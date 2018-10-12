module Fn

  class Afn

    extend Dry::Monads::Result::Mixin

    class << self

      #
      # Authorise Fns
      #

      # @param enforcer  A fn that responds to #call which will be performed when the authorisations fail
      # @param policies  An array of Policy checkers.  The policy takes optional state and ctx and returns a Maybe. Available checkers are:
      #                  + Afn.activity_policy
      #                  + Afn.slack_token_policy
      # @param ctx       A data structure of the user's authz context understood by the policy checker; e.g. the activity being performed
      # Example
      # > Afn.authorise.(Afn.auth_error_raise_enforcer.(PolicyEnforcement::AuthorisationFailed))
      #                .([Afn.activity_policy.(system_policy)])
      #                .(activity_ctx(:create))
      # => Success(nil) | raises a PolicyEnforcement::AuthorisationFailed
      # Use partial evaluation by establishing the enforcer and policies (which returns a partially applied authorise fn)
      # passing this to the services to be protected, which that evaluate the fn by providing the ctx.
      def authorise
        -> enforcer, policies, ctx {
          Fn.compose.(  finally_fn.(enforcer),
                        Fn.fmap_compose.(policies)
            ).(Success(ctx))
        }.curry
      end

      def finally_fn
        -> enforcer, v { Fn.either.(Fn.maybe_value_ok?).(Fn.identity).(-> x { enforcer.(x) } ).(v) }.curry
      end

      #
      # Enforcement Fns
      def nil_enforcer
        Fn.identity
      end

      def error_raiser
        -> exception, ctx { raise exception unless ctx.success? }.curry
      end

      #
      # Policy Fns
      #
      # A Policy gets the ctx, performs tests on the ctx, determines pass or fail and returns the ctx wrapped in an either
      #

      # Slack Policy looks for :token in the ctx, and ensures that token is configured in Account.
      # @param ctx {} expects a :token key/value provided by Slack.
      def slack_token_policy
        -> expected_token, ctx { Fn.either.(Fn.tests.(Fn.all?, slack_token_tests(expected_token)), Fn.success, Fn.failure ).(ctx) }.curry
      end

      def slack_token_tests(token)
        [
          key_present_test.(:token),
          valid_slack_token.(token)
        ]
      end

      # The Activity-based access control policy.
      # @param activities [String] A collection of activity strings assigned to the user obtained from Identity.  For example:
      #                            => ["lic:account:resource:billing_entity:*","lic:account:resource:payment_method:*"]
      # @param ctx {}  service/resource/action being tested; e.g. {:resource=>:invoice, :action=>:create}
      # Policy runs 4 tests:
      # + the ctx includes a :resource key
      # + the ctx includes an :action key
      # + the ctx includes an :activities
      # + and finally, the significant test, the service/resource/action match an activity
      def activity_policy
        -> activities, ctx {
          Fn.either.(Fn.tests.(Fn.all?, activity_tests), Fn.success, Fn.failure ).(ctx.merge(activities: activities))
        }.curry
      end

      def activity_tests
        [
          key_present_test.(:resource),
          key_present_test.(:action),
          key_present_test.(:activities),
          has_activity
        ]
      end


      #
      # Helper Fns
      #

      def key_present_test
        -> k, ctx { ctx.has_key? k }.curry
      end

      def valid_slack_token
        -> t, ctx { ctx[:token] == t }.curry
      end

      # s: system
      # r: r
      # a: action
      # activitys: user's activity enum
      def has_activity
        -> ctx  {
          activity_match.(ctx[:system], ctx[:resource], ctx[:action]).(ctx[:activities])
        }.curry
      end

      def activity_match
        -> s, r, a, activities {
          Fn.find.(policy_match.(s, r, a)).(activities)
        }.curry
      end

      def policy_match
        -> s, r, a, activity {
          Fn.compose.(  activity_token_matcher.(s,r,a),
                        Fn.coherse.(:to_sym),
                        Fn.split.(":")
            ).(activity)
        }.curry
      end

      def activity_token_matcher
        -> s,r,a,tokens {
          Fn.tests.(Fn.all?, activity_policy_tests.(s,r,a)).(tokens)
        }.curry
      end

      def activity_policy_tests
        -> s,r,a {
          [
            system_test.(s),
            resource_test.(r),
            action_test.(a)
          ]
        }
      end

      def system_test
        -> req, token { token_match.(req).(Fn.at.(1).(token)) }.curry
      end

      def resource_test
        -> req, token { token_match.(req).(Fn.at.(3).(token)) }.curry
      end

      def action_test
        -> req, token { token_match.(req).(Fn.at.(4).(token)) }.curry
      end

      def token_match
        -> req, token {
          req.nil? || req.size == 0 || token == :* || token == req
        }.curry
      end

    end

  end

end
