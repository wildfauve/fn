RSpec.describe Fn::Fn do

  context '#fmap_compose' do

    it 'runs all fns and returns success' do
      f1 = ->(v) { M.Success(v + 1) }
      f10 = ->(v) { M.Success(v + 10) }

      result = Fn::Fn.fmap_compose.([f1, f10]).(M.Success(0))
      expect(result).to be_success
      expect(result.value_or).to eq 11
    end

    it 'runs terminates when a failure is returned with the failure value' do
      f1 = ->(v) { M.Success(v + 1) }
      f10 = ->(v) { M.Failure(v) }
      f100 = ->(v) { M.Success(v + 100) }

      result = Fn::Fn.fmap_compose.([f1, f10, f100]).(M.Success(0))
      expect(result).to be_failure
      expect(result.failure).to eq 1
    end

  end

  context '#wrapper' do

  end

end
