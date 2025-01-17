version 1.0

import "../tasks/phylogenetic_inference/task_pirate.wdl" as pirate
import "../tasks/phylogenetic_inference/task_iqtree.wdl" as iqtree
import "../tasks/phylogenetic_inference/task_snp_dists.wdl" as snp_dists
import "../tasks/task_versioning.wdl" as versioning

workflow core_gene_snp_workflow {
  input {
    Array[File] gff3
    String cluster_name
    # if align = true, the pirate task will produce core and pangenome alignments for the sample set,
    # otherwise, pirate will only produce a pangenome summary
    Boolean align = true
    # use core_tree = true to produce a phylogenetic tree and snp distance matrix from the core genome alignment
    Boolean core_tree = true
    # use pan_tree = true to produce a phylogenetic tree and snp distance matrix from the pangenome alignment
    Boolean pan_tree = false
  }
  call pirate.pirate as pirate {
    input:
      gff3 = gff3,
      cluster_name = cluster_name,
      align = align
  }
  if (align) {
    if (core_tree) {
      call iqtree.iqtree as core_iqtree {
        input:
          alignment = select_first([pirate.pirate_core_alignment_fasta]),
          cluster_name = cluster_name
      }
      call snp_dists.snp_dists as core_snp_dists {
        input:
          alignment = select_first([pirate.pirate_core_alignment_fasta]),
          cluster_name = cluster_name
      }
    }
    if (pan_tree) {
      call iqtree.iqtree as pan_iqtree {
        input:
          alignment = select_first([pirate.pirate_pangenome_alignment_fasta]),
          cluster_name = cluster_name
      }
      call snp_dists.snp_dists as pan_snp_dists {
        input:
          alignment = select_first([pirate.pirate_pangenome_alignment_fasta]),
          cluster_name = cluster_name
      }
    }
  }
  call versioning.version_capture{
    input:
  }
  output {
    # Version Capture
    String core_gene_snp_wf_version = version_capture.phbg_version
    String core_gene_snp_wf_analysis_date = version_capture.date
    # pirate_outputs
    File pirate_pangenome_summary = pirate.pirate_pangenome_summary
    File pirate_gene_families_ordered = pirate.pirate_gene_families_ordered
    File? pirate_core_alignment_fasta = pirate.pirate_core_alignment_fasta
    File? pirate_core_alignment_gff = pirate.pirate_core_alignment_gff
    File? pirate_pan_alignment_fasta = pirate.pirate_pangenome_alignment_fasta
    File? pirate_pan_alignment_gff = pirate.pirate_pangenome_alignment_gff
    File? pirate_presence_absence_csv = pirate.pirate_presence_absence_csv
    String pirate_docker_image = pirate.pirate_docker_image
    # snp_dists outputs
    String? pirate_snps_dists_version = select_first([core_snp_dists.version,pan_snp_dists.version,""])
    File? pirate_core_snp_matrix = core_snp_dists.snp_matrix
    File? pirate_pan_snp_matrix = pan_snp_dists.snp_matrix
    # iqtree outputs
    String? pirate_iqtree_version = select_first([core_iqtree.version,pan_iqtree.version,""])
    File? pirate_iqtree_core_tree = core_iqtree.ml_tree
    File? pirate_iqtree_pan_tree = pan_iqtree.ml_tree
  }
}
