class Roda
  module RodaPlugins
    module Rodauth
      CreateAccount = Feature.define(:create_account) do
        route 'create-account'
        notice_flash "Your account has been created"
        error_flash "There was an error creating your account"
        view 'create-account', 'Create Account'
        redirect

        auth_value_methods :create_account_autologin?
        auth_methods :new_account

        get_block do |r|
          rodauth.create_account_view
        end

        post_block do |r|
          auth = rodauth

          if r[auth.login_param] == r[auth.login_confirm_param]
            if r[auth.password_param] == r[auth.password_confirm_param]
              if auth.password_meets_requirements?(r[auth.password_param].to_s)
                auth.new_account(r[auth.login_param])
                auth.transaction do
                  if auth.save_account
                    auth.set_password(r[auth.password_param].to_s)
                    if auth.verify_created_accounts?
                      auth.generate_verify_account_key_value
                      auth.create_verify_account_key
                      auth.send_verify_account_email
                    elsif auth.create_account_autologin?
                      auth.update_session
                    end
                    auth.set_notice_flash auth.create_account_notice_flash
                    r.redirect(auth.create_account_redirect)
                  else
                    @login_error = auth.login_errors_message
                  end
                end
              else
                @password_error = auth.password_does_not_meet_requirements_message
              end
            else
              @password_error = auth.passwords_do_not_match_message
            end
          else
            @login_error = auth.logins_do_not_match_message
          end

          auth.set_error_flash auth.create_account_error_flash
          auth.create_account_view
        end

        def create_account_autologin?
          false
        end

        def new_account(login)
          @account = account_model.new(login_column=>login)
          unless verify_created_accounts?
            account.set(account_status_id=>account_open_status_value)
          end
        end

        def save_account
          account.save(:raise_on_failure=>false)
        end
      end
    end
  end
end