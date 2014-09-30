# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'spec_helper'

describe IdentifierResolvers::ArxivFromReference do

  context "Interface" do

    it "should have a resolve method" do
      resolver = described_class.new(:root, :refs)
      expect(resolver).to  respond_to(:resolve)
    end

  end

  context "Parsing Arxiv IDs" do

    def make_resolver(node)
      node = Loofah.xml_document(node)
      id   = node.at_css('ref').attr('id')

      ref = Hashie::Mash.new(
          id:   id,
          node: node,
          text: node.text
      )

      resolver = described_class.new(:root, { id => ref })
    end

    it "should resolve from XML text" do
      resolver = make_resolver <<-XML
        <ref id="ref-1">
          <comment>arxiv:<a>1234.5678</a></comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', uri_source: :ref, uri:'1234.5678', uri_type: :arxiv)
      resolver.resolve
    end

    it "should resolve from XML" do
      resolver = make_resolver <<-XML
        <ref id="ref-1">
          <comment><elem attr="http://arxiv.org/abs/1234.5678" /></comment>
        </ref>
      XML

      expect(resolver).to receive(:set_result).with('ref-1', uri_source: :ref, uri:'1234.5678', uri_type: :arxiv)
      resolver.resolve
    end

    context "When the source attribute contains /arxiv/" do

      it "should resolve from the volume" do
        resolver = make_resolver <<-XML
          <ref id="ref-1">
            <source>Arxiv preprint</source>
            <volume>12345678</volume>
          </ref>
        XML

        expect(resolver).to receive(:set_result).with('ref-1', uri_source: :ref, uri:'1234.5678', uri_type: :arxiv)
        resolver.resolve
      end

      it "should resolve from the fpage" do
        resolver = make_resolver <<-XML
          <ref id="ref-1">
            <source>Arxiv preprint</source>
            <fpage>12345678</fpage>
          </ref>
        XML

        expect(resolver).to receive(:set_result).with('ref-1', uri_source: :ref, uri:'1234.5678', uri_type: :arxiv)
        resolver.resolve
      end

      it "should resolve from the volume and fpage" do
        resolver = make_resolver <<-XML
          <ref id="ref-1">
            <source>Arxiv preprint</source>
            <volume>1234</volume>
            <fpage>5678</fpage>
          </ref>
        XML

        expect(resolver).to receive(:set_result).with('ref-1', uri_source: :ref, uri:'1234.5678', uri_type: :arxiv)
        resolver.resolve
      end

    end

  end

end
