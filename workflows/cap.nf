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

// Subworkflows
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'

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
            name: 'nf_core_cap_software_versions.yml',
            sort: true,
            newLine: true
        )

    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
