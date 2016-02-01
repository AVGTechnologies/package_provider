# Class handling unit tests for Parser class
describe PackageProvider::Parser do
  let(:parser) { PackageProvider::Parser.new }
  let(:tsd_request2parts) { 'tsd_request2parts' }

  let(:git_repo_request) do
    'ssh://git@github.com:AVG-Automation/package_provider.git|master'
  end
  let(:simple_request) do
    'ddtf|master'
  end
  let(:simple_request_commit_hash) do
    'ddtf|4642e6cbebcaa4a7bf94703da1d8ab827b801b34'
  end
  let(:simple_complete_request) do
    'ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'
  end
  let(:simple_request_override) do
    'ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'\
    '(source_folder>destination_folder)'
  end
  let(:simple_request_two_override) do
    'ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'\
    '(source_folder>destination_folder, take_this_folder)'
  end
  let(:two_simple_request) do
    'ddtf|master, dev|av/devel'
  end
  let(:two_simple_request_commit_hash) do
    'ddtf|4642e6cbebcaa4a7bf94703da1d8ab827b801b34,'\
    'dev|7146b95092f07109bf97fd3554f25e6683de0796'
  end
  let(:two_requests_complete) do
    'ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34,'\
    'dev|my_branch:7146b95092f07109bf97fd3554f25e6683de0796'
  end
  let(:two_requests_complete_override) do
    'ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'\
    '(source_folder>dest_folder),'\
    ' dev|my_branch:7146b95092f07109bf97fd3554f25e6683de0796'\
    '(source_folder2>dest_folder2)'
  end
  let(:two_requests_complete_two_override) do
    'ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'\
    '(source_folder  > dest_folder, my_desired_folder),'\
    'dev|my_branch:7146b95092f07109bf97fd3554f25e6683de0796'\
    '(source_folder2>dest_folder2, my_desired_folder2)'
  end
  let(:simple_request_with_shortened_commit_hash) { 'ddtf|9329696ea08' }

  describe '#tsd_request2parts' do
    context 'with single repo' do
      it 'parses git url and branch, no override' do
        expect(parser.send(tsd_request2parts, git_repo_request)).to(
          eq(['ssh://git@github.com:AVG-Automation/package_provider.git|master']
            ))
      end
      it 'parses alias and branch, no override' do
        expect(
          parser.send(tsd_request2parts, simple_request)
        ).to eq(['ddtf|master'])
      end
      it 'parses alias and commit hash present, no override' do
        expect(
          parser.send(tsd_request2parts, simple_request_commit_hash)
        ).to eq(['ddtf|4642e6cbebcaa4a7bf94703da1d8ab827b801b34'])
      end
      context 'that has alias, branch and commit hash' do
        it 'parses no override' do
          expect(
            parser.send(tsd_request2parts, simple_complete_request)
          ).to eq(['ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'])
        end
        it 'parses one override with destination' do
          expect(parser.send(tsd_request2parts, simple_request_override)).to(
            eq(['ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'\
                '(source_folder>destination_folder)']))
        end
        it 'parses two override (one without destination)' do
          expect(
            parser.send(tsd_request2parts, simple_request_two_override)
          ).to(eq(['ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'\
                   '(source_folder>destination_folder, take_this_folder)']))
        end
      end
    end

    context 'with multiple repo' do
      it 'parses alias and branch, no override' do
        expect(
          parser.send(tsd_request2parts, two_simple_request)
        ).to eq(['ddtf|master', 'dev|av/devel'])
      end
      it 'parses alias and commit hash, no override' do
        expect(
          parser.send('tsd_request2parts', two_simple_request_commit_hash)
        ).to(eq(['ddtf|4642e6cbebcaa4a7bf94703da1d8ab827b801b34',
                 'dev|7146b95092f07109bf97fd3554f25e6683de0796']))
      end
      context 'that has alias, branch and commit hash' do
        it 'parses no override' do
          expect(
            parser.send(tsd_request2parts, two_requests_complete)
          ).to(eq(['ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34',
                   'dev|my_branch:7146b95092f07109bf97fd3554f25e6683de0796']))
        end
        it 'parses one override with destination' do
          expect(
            parser.send(tsd_request2parts, two_requests_complete_override)
          ).to(eq(['ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'\
                   '(source_folder>dest_folder)',
                   'dev|my_branch:7146b95092f07109bf97fd3554f25e6683de0796'\
                   '(source_folder2>dest_folder2)']))
        end
        it 'parses two override (one without destination)' do
          expect(
            parser.send(tsd_request2parts, two_requests_complete_two_override)
          ).to(eq(['ddtf|master:4642e6cbebcaa4a7bf94703da1d8ab827b801b34'\
                   '(source_folder  > dest_folder, my_desired_folder)',
                   'dev|my_branch:7146b95092f07109bf97fd3554f25e6683de0796'\
                   '(source_folder2>dest_folder2, my_desired_folder2)']))
        end
      end
    end
  end

  describe '#parse' do
    it 'when branch is specified' do
      expect(
        parser.parse(simple_request)
      ).to(eq([PackageProvider::RepositoryRequest.new('ddtf', nil, 'master')]))
    end
    it 'when commit hash is specified' do
      expect(
        parser.parse(simple_request_commit_hash)
      ).to(eq([PackageProvider::RepositoryRequest.new(
        'ddtf', '4642e6cbebcaa4a7bf94703da1d8ab827b801b34', nil)]))
    end
    it 'when both commit hash and branch are specified' do
      expect(
        parser.parse(simple_complete_request)
      ).to(eq([PackageProvider::RepositoryRequest.new(
        'ddtf', '4642e6cbebcaa4a7bf94703da1d8ab827b801b34', 'master')]))
    end
    it 'when both commit hash and branch with folder overide are specified' do
      result = PackageProvider::RepositoryRequest.new(
        'ddtf', '4642e6cbebcaa4a7bf94703da1d8ab827b801b34', 'master')

      result.add_folder_override('source_folder', 'destination_folder')

      expect(parser.parse(simple_request_override)).to(eq([result]))
    end
    it 'multiple repo both commit hash and branch with multiple override' do
      result = PackageProvider::RepositoryRequest.new(
        'ddtf',
        '4642e6cbebcaa4a7bf94703da1d8ab827b801b34',
        'master')
      result.add_folder_override('source_folder', 'dest_folder')

      result2 = PackageProvider::RepositoryRequest.new(
        'dev', '7146b95092f07109bf97fd3554f25e6683de0796', 'my_branch')

      result2.add_folder_override('source_folder2', 'dest_folder2')

      expect(
        parser.parse(two_requests_complete_override)
      ).to(eq([result, result2]))
    end
    it 'parses shortened commit hash as branch' do
      expect(
        parser.parse(simple_request_with_shortened_commit_hash)
      ).to(eq([PackageProvider::RepositoryRequest.new('ddtf', nil, '9329696ea08')]))
    end
    context 'fails' do
      it 'with invalid request' do
        expect { parser.parse('dev/devel') }.to raise_error(
          PackageProvider::Parser::ParsingError)
      end
      it 'with invalid request with two branches' do
        expect { parser.parse('dev/devel|devel, master') }.to raise_error(
          PackageProvider::Parser::ParsingError)
      end
      it 'with invalid request with no source' do
        expect { parser.parse('dev/devel|') }.to raise_error(
          PackageProvider::Parser::ParsingError)
      end
    end
  end
end
