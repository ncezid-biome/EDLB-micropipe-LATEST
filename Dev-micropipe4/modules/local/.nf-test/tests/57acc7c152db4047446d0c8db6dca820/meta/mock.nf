import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2


// comes from testflight to find json files
params.nf_testflight_output  = "json"

// process mapping
def input = []

                // define inputs of the process here. Example:
                input[0] = path("/scicomp/home-pure/suj7/Dev-micropipe4/modules/local/fast5_tiny/")
                
//----

// include test process
include { basecalling } from '/scicomp/home-pure/suj7/Dev-micropipe4/modules/local/basecalling.nf'


// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .excludeNulls()  // Do not include fields with value null..
        .addConverter(Path) { value -> value.toString() } // Custom converter for Path. Only filename
        .build()


workflow {

  basecalling(*input)

  // consumes all output channels and stores items in a json
  def channel = Channel.empty()
  for (def name in basecalling.out.getNames()) {
      channel << tuple(name, basecalling.out.getProperty(name))
  }

  channel.subscribe { outputTupel ->
    def sortedList = outputTupel[1].toList()
    sortedList.subscribe { list ->
      def map = new HashMap()
      def outputName = outputTupel[0]
      map[outputName] = list
      new File("${params.nf_testflight_output}/output_${outputName}.json").text = jsonOutput.toJson(map)
    }
  }
  
}


workflow.onComplete {

	def result = [
		success: workflow.success,
		exitStatus: workflow.exitStatus,
		errorMessage: workflow.errorMessage,
		errorReport: workflow.errorReport
	]
    new File("${params.nf_testflight_output}/workflow.json").text = jsonOutput.toJson(result)
    
}