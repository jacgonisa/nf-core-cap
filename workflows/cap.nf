/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Local modules
include { CHECK_DEPS           } from '../modules/local/check_deps/main'
include { TRASH2               } from '../modules/local/trash2/main'
include { GET_METADATA         } from '../modules/local/get_metadata/main'
include { FILTER_TRASH         } from '../modules/local/filter_trash/main'
include { MERGE_CLASSES        } from '../modules/local/merge_classes/main'
include { PARSE_TES            } from '../modules/local/parse_tes/main'
include { FILTER_TES           } from '../modules/local/filter_tes/main'
include { PARSE_GENES          } from '../modules/local/parse_genes/main'
include { FILTER_GENES         } from '../modules/local/filter_genes/main'
include { SCORE_CENTROMERIC    } from '../modules/local/score_centromeric/main'
include { PREDICT_CENTROMERIC  } from '../modules/local/predict_centromeric/main'
include { GC                   } from '../modules/local/gc/main'
include { CTW                  } from '../modules/local/ctw/main'
include { CAP as CAP_VIZ       } from '../modules/local/cap/main'

// nf-core modules
include { MULTIQC              } from '../modules/nf-core/multiqc/main'

// Subworkflows
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_cap_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow CAP {

    take:
    ch_assembly    // channel: path to assembly file
    ch_te_gff      // channel: optional path to TE GFF file
    ch_gene_gff    // channel: optional path to gene GFF file
    ch_templates   // channel: optional path to templates file

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // MODULE: Check dependencies
    //
    CHECK_DEPS()
    ch_versions = ch_versions.mix(CHECK_DEPS.out.versions)
    ready_ch = CHECK_DEPS.out.ready

    //
    // MODULE: Run TRASH2 for repeat detection
    //
    trash_in = ch_assembly.map { assembly ->
        def t = params.templates ? file(params.templates) : null
        tuple(assembly, t)
    }
    TRASH2(trash_in, ready_ch)
    ch_versions = ch_versions.mix(TRASH2.out.versions)

    //
    // MODULE: Filter TRASH2 results
    //
    FILTER_TRASH(TRASH2.out.trash_results)
    ch_versions = ch_versions.mix(FILTER_TRASH.out.versions)

    //
    // MODULE: Merge and reclassify repeat classes
    //
    MERGE_CLASSES(FILTER_TRASH.out.filtered)
    ch_versions = ch_versions.mix(MERGE_CLASSES.out.versions)

    //
    // MODULE: Get assembly metadata
    //
    GET_METADATA(ch_assembly)
    ch_versions = ch_versions.mix(GET_METADATA.out.versions)

    //
    // MODULE: Optional - Parse and filter TEs
    //
    if (params.te_gff) {
        PARSE_TES(ch_te_gff)
        ch_versions = ch_versions.mix(PARSE_TES.out.versions)

        FILTER_TES(PARSE_TES.out.parsed)
        ch_versions = ch_versions.mix(FILTER_TES.out.versions)
        te_filtered = FILTER_TES.out.filtered
    } else {
        te_filtered = Channel.of('NO_FILE')
    }

    //
    // MODULE: Optional - Parse and filter genes
    //
    if (params.gene_gff) {
        PARSE_GENES(ch_gene_gff)
        ch_versions = ch_versions.mix(PARSE_GENES.out.versions)

        FILTER_GENES(PARSE_GENES.out.parsed)
        ch_versions = ch_versions.mix(FILTER_GENES.out.versions)
        gene_filtered = FILTER_GENES.out.filtered
    } else {
        gene_filtered = Channel.of('NO_FILE')
    }

    //
    // MODULE: Score centromeric classes
    //
    SCORE_CENTROMERIC(
        ch_assembly,
        MERGE_CLASSES.out.reclassed,
        GET_METADATA.out.metadata,
        te_filtered,
        gene_filtered
    )
    ch_versions = ch_versions.mix(SCORE_CENTROMERIC.out.versions)

    //
    // MODULE: Predict centromeric regions using ML
    //
    PREDICT_CENTROMERIC(SCORE_CENTROMERIC.out.scores)
    ch_versions = ch_versions.mix(PREDICT_CENTROMERIC.out.versions)

    //
    // MODULE: Calculate GC content and CTW in parallel
    //
    GC(ch_assembly)
    ch_versions = ch_versions.mix(GC.out.versions)

    CTW(ch_assembly)
    ch_versions = ch_versions.mix(CTW.out.versions)

    //
    // MODULE: Final CAP visualization
    //
    CAP_VIZ(
        ch_assembly,
        PREDICT_CENTROMERIC.out.predictions,
        MERGE_CLASSES.out.reclassed,
        GET_METADATA.out.metadata,
        te_filtered,
        gene_filtered,
        GC.out.gc,
        CTW.out.ctw,
        SCORE_CENTROMERIC.out.scores
    )
    ch_versions = ch_versions.mix(CAP_VIZ.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_cap_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
