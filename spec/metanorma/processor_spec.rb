require "spec_helper"
require "fileutils"

RSpec.describe Metanorma::Ogc::Processor do
  registry = Metanorma::Registry.instance
  registry.register(Metanorma::Ogc::Processor)

  let(:processor) do
    registry.find_processor(:ogc)
  end

  it "registers against metanorma" do
    expect(processor).not_to be nil
  end

  it "registers output formats against metanorma" do
    output = <<~"OUTPUT"
      [[:doc, "doc"], [:html, "html"], [:pdf, "pdf"], [:presentation, "presentation.xml"], [:rxl, "rxl"], [:xml, "xml"]]
    OUTPUT

    expect(processor.output_formats.sort.to_s).to be_equivalent_to output
  end

  it "registers version against metanorma" do
    expect(processor.version.to_s).to match(%r{^Metanorma::Ogc })
  end

  it "generates IsoDoc XML from a blank document" do
    input = <<~"INPUT"
      #{ASCIIDOC_BLANK_HDR}
    INPUT

    output = <<~"OUTPUT"
          #{BLANK_HDR}
          <preface>#{SECURITY}</preface>
      <sections/>
      </ogc-standard>
    OUTPUT

    expect(xmlpp(strip_guid(processor
      .input_to_isodoc(input, nil)))).to be_equivalent_to (xmlpp(output))
  end

  it "generates HTML from IsoDoc XML" do
    FileUtils.rm_f "test.xml"
    input = <<~"INPUT"
      <ogc-standard xmlns="https://standards.opengeospatial.org/document">
        <sections>
          <terms id="H" obligation="normative"><title>1.<tab/>Terms, Definitions, Symbols and Abbreviated Terms</title>
            <term id="J">
            <name>1.1.</name>
              <preferred>Term2</preferred>
            </term>
          </terms>
        </sections>
      </ogc-standard>
    INPUT

    output = xmlpp(<<~"OUTPUT")
      <main class="main-section">
        <button onclick="topFunction()" id="myBtn" title="Go to top">Top</button>
        <p class="zzSTDTitle1"></p>
        <div id="H">
          <h1 id="toc0">1.&#xA0; Terms, Definitions, Symbols and Abbreviated Terms</h1>
          <h2 class='TermNum' style='text-align:left;' id='J'>1.1.&#xA0;Term2</h2>
        </div>
      </main>
    OUTPUT

    processor.output(input, "test.xml", "test.html", :html)

    expect(
      xmlpp(File.read("test.html", encoding: "utf-8")
      .gsub(%r{^.*<main}m, "<main")
      .gsub(%r{</main>.*}m, "</main>")),
    ).to be_equivalent_to output
  end
end
