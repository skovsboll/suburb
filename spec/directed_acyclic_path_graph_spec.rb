require_relative '../lib/directed_acyclic_path_graph'

describe Suburb::DirectedAcyclicPathGraph do
  it '#root_path' do
    dag = described_class.new('.')
    expect(dag.root_path.absolute?).to be(true)
  end

  context '#nodes' do
    it 'same dir' do
      dag = described_class.new('.')
      dag.add_node('mjallo')
      expect(dag.nodes[Dir.pwd + '/mjallo'].path).to eq(dag.root_path + 'mjallo')
    end
  end

  context '#add_node' do
    context 'relative paths' do
      it 'same dir' do
        dag = described_class.new('.')
        dag.add_node('mjallo')
        expect(dag.nodes.values[0].path).to eq(dag.root_path + 'mjallo')
      end

      it 'sub dir' do
        dag = described_class.new('.')
        dag.add_node('sub/dir')
        expect(dag.nodes.values[0].path).to eq(dag.root_path + 'sub/dir')
      end

      it 'outside root path' do
        dag = described_class.new('.')
        expect do
          dag.add_node('../mjallo')
        end.to raise_error(RuntimeError)
      end
    end

    context 'absolute paths' do
      it 'same dir' do
        dag = described_class.new('/etc')
        dag.add_node('/etc/thing.txt')
        expect(dag.nodes.values[0].path.to_s).to eq('/etc/thing.txt')
      end

      it 'sub dir' do
        dag = described_class.new('/etc')
        dag.add_node('/etc/sub/dir')
        expect(dag.nodes.values[0].path).to eq(dag.root_path + 'sub/dir')
      end

      it 'outside root path' do
        dag = described_class.new('/etc')
        expect do
          dag.add_node('/mjallo')
        end.to raise_error(RuntimeError)
      end
    end
  end

  context '#add_dependency' do
    it 'absolute' do
      dag = described_class.new('/etc')
      dag.add_node('/etc/thing.txt')
      dag.add_dependency('/etc/thing.txt', '/etc/dep.md')
      expect(dag.nodes.values[0].dependencies[0].path.to_s).to eq('/etc/dep.md')
    end

    it 'relative' do
      dag = described_class.new('.')
      dag.add_node('sub/thing.txt')
      dag.add_dependency('sub/thing.txt', 'sub2/dep.md')
      expect(dag.nodes.values[0].dependencies[0].path).to eq(dag.root_path + 'sub2/dep.md')
    end

    it 'outside root path' do
      dag = described_class.new('/etc')
      dag.add_node('/etc/master')
      expect do
        dag.add_dependency('/etc/master', '/var/dep')
      end.to raise_error(RuntimeError)
    end

    it 'cycle-1' do
      dag = described_class.new('.')
      dag.add_node('one')
      expect do
        dag.add_dependency('one', 'one')
      end.to raise_error(RuntimeError)
    end

    it 'cycle-2' do
      dag = described_class.new('.')
      dag.add_node('one')
      dag.add_node('two')
      dag.add_dependency('one', 'two')
      expect do
        dag.add_dependency('two', 'one')
      end.to raise_error(RuntimeError)
    end

    it 'cycle-3' do
      dag = described_class.new('.')
      dag.add_node('one')
      dag.add_node('two')
      dag.add_node('three')
      dag.add_dependency('one', 'two')
      dag.add_dependency('two', 'three')
      expect do
        dag.add_dependency('three', 'one')
      end.to raise_error(RuntimeError)
    end
  end
end
