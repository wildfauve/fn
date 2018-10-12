RSpec.describe Fn::Afn do

  context '#token' do
    it 'validates the JWT' do

    end
  end

  context '#authorise' do

    it 'runs the authorisation policies' do
      policies = [ -> ctx { M.Success(ctx) } ]
      result = Fn::Afn.authorise.(Fn::Afn.nil_enforcer).(policies).({context: "stuff"})

      expect(result).to be_success
    end

    it 'returns a failure when the policy is not met, and the enforcer is nil' do
      policies = [ -> ctx { M.Failure(ctx) } ]

      result = Fn::Afn.authorise.(Fn::Afn.nil_enforcer).(policies).({context: "stuff"})

      expect(result).to be_failure
    end

    it 'handles multiple policies' do
      policies = [ -> ctx { M.Success(ctx) }, -> ctx { M.Success(ctx) } ]

      result = Fn::Afn.authorise.(Fn::Afn.nil_enforcer).(policies).({context: "stuff"})

      expect(result).to be_success
    end

    it 'handles terminates on first failure' do
      policies = [ -> ctx { M.Success(ctx) }, -> ctx { M.Failure("just to prove that it stopped") }, -> ctx { M.Success(ctx) } ]

      result = Fn::Afn.authorise.(Fn::Afn.nil_enforcer).(policies).({context: "stuff"})

      expect(result).to be_failure
      expect(result.failure).to eq("just to prove that it stopped")
    end


    it 'raises an error from the enforcer when using a raising enforcer' do
      policies = [ -> ctx { M.Failure(ctx) } ]
      expect {
              Fn::Afn.authorise.(Fn::Afn.auth_error_raise_enforcer.(StandardError)).(policies).({context: "stuff"})
            }.to raise_error StandardError
    end

  end

  context '#slack_token_policy' do

    it 'return success when the tokens match, and returns the ctx' do
      result = Fn::Afn.slack_token_policy.("slack_token").({token: "slack_token"})

      expect(result).to be_success
      expect(result.value_or).to eq({token: "slack_token"})
    end

    it 'return failure when the tokens dont match, and returns the ctx' do
      result = Fn::Afn.slack_token_policy.("slack_token").({token: "bad_token"})

      expect(result).to be_failure
      expect(result.failure).to eq({token: "bad_token"})
    end

  end

  context '#activity_policy' do

    it 'passes the activity check' do
      activities = ["lic:account:resource:billing_entity:show"]

      result = Fn::Afn.activity_policy.(activities).(system: ENV["SERVICE_NAME"], resource: :billing_entity, action: :show)

      expect(result).to be_success
    end

    it 'fails the activity check when the activity action does not match' do
      activities = ["lic:account:resource:billing_entity:read"]
      result = Fn::Afn.activity_policy.(activities).(resource: :billing_entity, action: :show)

      expect(result).to be_failure
    end

    it 'fails the activity check when the activity resource does not match' do
      activities = ["lic:account:resource:some_other_resource:show"]
      result = Fn::Afn.activity_policy.(activities).(resource: :billing_entity, action: :show)

      expect(result).to be_failure
    end

    it 'passes with the action is a wildcard' do
      activities = ["lic:account:resource:billing_entity:*"]
      result = Fn::Afn.activity_policy.(activities).(resource: :billing_entity, action: :show)

      expect(result).to be_success
    end

    it 'passes with the resource and action are wildcards' do
      activities = ["lic:account:resource:*:*"]
      result = Fn::Afn.activity_policy.(activities).(resource: :billing_entity, action: :show)

      expect(result).to be_success
    end


  end

  context '#auth_error_raise_enforcer' do

    it 'raises the error provided' do

      expect {
        Fn::Afn.error_raiser.(StandardError).(M.Failure("boom!"))
      }.to raise_error StandardError

    end

  end

end
