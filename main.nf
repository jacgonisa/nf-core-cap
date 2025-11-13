#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/cap
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/cap
    Website: https://nf-co.re/cap
    Slack  : https://nfcore.slack.com/channels/cap
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CAP  } from './workflows/cap'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    GENOME PARAMETER VALUES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// CAP-specific parameters - assembly file is required
// Optional TE and gene GFF files, and custom templates

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//
workflow NFCORE_CAP {

    take:
    ch_assembly    // channel: path to assembly file
    ch_te_gff      // channel: optional path to TE GFF file
    ch_gene_gff    // channel: optional path to gene GFF file
    ch_templates   // channel: optional path to templates file

    main:

    //
    // WORKFLOW: Run pipeline
    //
    CAP (
        ch_assembly,
        ch_te_gff,
        ch_gene_gff,
        ch_templates
    )
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:

    //
    // Check required parameters
    //
    if (!params.assembly) {
        error "Please provide an assembly file with --assembly"
    }

    //
    // Create input channels for CAP pipeline
    //
    ch_assembly = params.assembly ?
        Channel.fromPath(params.assembly, checkIfExists: true) :
        Channel.empty()

    ch_te_gff = params.te_gff ?
        Channel.fromPath(params.te_gff, checkIfExists: true) :
        Channel.empty()

    ch_gene_gff = params.gene_gff ?
        Channel.fromPath(params.gene_gff, checkIfExists: true) :
        Channel.empty()

    ch_templates = params.templates ?
        Channel.fromPath(params.templates, checkIfExists: true) :
        Channel.empty()

    //
    // WORKFLOW: Run main workflow
    //
    NFCORE_CAP (
        ch_assembly,
        ch_te_gff,
        ch_gene_gff,
        ch_templates
    )
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
