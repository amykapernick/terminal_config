#!/usr/bin/env bash

if ! type __ltrim_colon_completions >/dev/null 2>&1; then
  #   Copyright © 2006-2008, Ian Macdonald <ian@caliban.org>
  #             © 2009-2017, Bash Completion Maintainers
  __ltrim_colon_completions() {
      # If word-to-complete contains a colon,
      # and bash-version < 4,
      # or bash-version >= 4 and COMP_WORDBREAKS contains a colon
      if [[
          "$1" == *:* && (
              ${BASH_VERSINFO[0]} -lt 4 ||
              (${BASH_VERSINFO[0]} -ge 4 && "$COMP_WORDBREAKS" == *:*)
          )
      ]]; then
          # Remove colon-word prefix from COMPREPLY items
          local colon_word=${1%${1##*:}}
          local i=${#COMPREPLY[*]}
          while [ $((--i)) -ge 0 ]; do
              COMPREPLY[$i]=${COMPREPLY[$i]#"$colon_word"}
          done
      fi
  }
fi

_twilio()
{

  local cur="${COMP_WORDS[COMP_CWORD]}" opts IFS=$' \t\n'
  COMPREPLY=()

  local commands="
debugger:logs:list --properties --streaming --log-level --start-date --end-date --profile --cli-log-level --cli-output-format
email:send --to --from --subject --text --attachment --no-attachment --cli-log-level --cli-output-format
email:set --from --subject
feedback 
login --auth-token --force --region --profile --cli-log-level --cli-output-format
phone-numbers:list --properties --profile --cli-log-level --cli-output-format --account-sid
phone-numbers:update --friendly-name --sms-url --sms-method --sms-fallback-url --sms-fallback-method --voice-url --voice-method --voice-fallback-url --voice-fallback-method --profile --cli-log-level --cli-output-format --account-sid
plugins:available 
profiles:create --auth-token --force --region --profile --cli-log-level --cli-output-format
profiles:list --cli-log-level --cli-output-format
profiles:remove --profile --cli-log-level --cli-output-format
profiles:use --cli-log-level --cli-output-format
autocomplete --refresh-cache
help --all
plugins --core
plugins:install --help --verbose --force
plugins:link --help --verbose
plugins:uninstall --help --verbose
plugins:update --help --verbose
api:accounts:v1:credentials:aws:create --account-sid --credentials --friendly-name --properties --profile --cli-log-level --cli-output-format
api:accounts:v1:credentials:aws:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:accounts:v1:credentials:aws:update --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:accounts:v1:credentials:aws:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:accounts:v1:credentials:aws:remove --sid --profile --cli-log-level --cli-output-format
api:accounts:v1:credentials:public-keys:create --account-sid --friendly-name --public-key --properties --profile --cli-log-level --cli-output-format
api:accounts:v1:credentials:public-keys:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:accounts:v1:credentials:public-keys:update --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:accounts:v1:credentials:public-keys:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:accounts:v1:credentials:public-keys:remove --sid --profile --cli-log-level --cli-output-format
api:core:accounts:create --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:accounts:list --friendly-name --status --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:addresses:create --account-sid --auto-correct-address --city --customer-name --emergency-enabled --friendly-name --iso-country --postal-code --region --street --properties --profile --cli-log-level --cli-output-format
api:core:addresses:list --account-sid --customer-name --friendly-name --iso-country --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:addresses:dependent-phone-numbers:list --account-sid --address-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:addresses:update --account-sid --sid --auto-correct-address --city --customer-name --emergency-enabled --friendly-name --postal-code --region --street --properties --profile --cli-log-level --cli-output-format
api:core:addresses:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:addresses:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:applications:create --account-sid --api-version --friendly-name --message-status-callback --sms-fallback-method --sms-fallback-url --sms-method --sms-status-callback --sms-url --status-callback --status-callback-method --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-url --properties --profile --cli-log-level --cli-output-format
api:core:applications:list --account-sid --friendly-name --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:applications:update --account-sid --sid --api-version --friendly-name --message-status-callback --sms-fallback-method --sms-fallback-url --sms-method --sms-status-callback --sms-url --status-callback --status-callback-method --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-url --properties --profile --cli-log-level --cli-output-format
api:core:applications:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:applications:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:authorized-connect-apps:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:authorized-connect-apps:fetch --account-sid --connect-app-sid --properties --profile --cli-log-level --cli-output-format
api:core:available-phone-numbers:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:available-phone-numbers:fetch --account-sid --country-code --properties --profile --cli-log-level --cli-output-format
api:core:available-phone-numbers:local:list --account-sid --country-code --area-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:available-phone-numbers:machine-to-machine:list --account-sid --country-code --area-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:available-phone-numbers:mobile:list --account-sid --country-code --area-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:available-phone-numbers:national:list --account-sid --country-code --area-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:available-phone-numbers:shared-cost:list --account-sid --country-code --area-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:available-phone-numbers:toll-free:list --account-sid --country-code --area-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:available-phone-numbers:voip:list --account-sid --country-code --area-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:balance:list --account-sid --properties --limit --profile --cli-log-level --cli-output-format
api:core:calls:create --account-sid --application-sid --async-amd --async-amd-status-callback --async-amd-status-callback-method --byoc --call-reason --caller-id --fallback-method --fallback-url --from --machine-detection --machine-detection-silence-timeout --machine-detection-speech-end-threshold --machine-detection-speech-threshold --machine-detection-timeout --method --record --recording-channels --recording-status-callback --recording-status-callback-event --recording-status-callback-method --send-digits --sip-auth-password --sip-auth-username --status-callback --status-callback-event --status-callback-method --timeout --to --trim --twiml --url --properties --profile --cli-log-level --cli-output-format
api:core:calls:list --account-sid --to --from --parent-call-sid --status --start-time --start-time-before --start-time-after --end-time --end-time-before --end-time-after --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:calls:feedback-summary:create --account-sid --end-date --include-subaccounts --start-date --status-callback --status-callback-method --properties --profile --cli-log-level --cli-output-format
api:core:calls:feedback-summary:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:calls:feedback-summary:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:calls:feedback:update --account-sid --call-sid --issue --quality-score --properties --profile --cli-log-level --cli-output-format
api:core:calls:feedback:fetch --account-sid --call-sid --properties --profile --cli-log-level --cli-output-format
api:core:calls:notifications:list --account-sid --call-sid --log --message-date --message-date-before --message-date-after --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:calls:notifications:fetch --account-sid --call-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:calls:payments:create --account-sid --call-sid --bank-account-type --charge-amount --currency --description --idempotency-key --input --min-postal-code-length --parameter --payment-connector --payment-method --postal-code --security-code --status-callback --timeout --token-type --valid-card-types --properties --profile --cli-log-level --cli-output-format
api:core:calls:payments:update --account-sid --call-sid --sid --capture --idempotency-key --status --status-callback --properties --profile --cli-log-level --cli-output-format
api:core:calls:recordings:create --account-sid --call-sid --recording-channels --recording-status-callback --recording-status-callback-event --recording-status-callback-method --trim --properties --profile --cli-log-level --cli-output-format
api:core:calls:recordings:list --account-sid --call-sid --date-created --date-created-before --date-created-after --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:calls:recordings:update --account-sid --call-sid --sid --pause-behavior --status --properties --profile --cli-log-level --cli-output-format
api:core:calls:recordings:fetch --account-sid --call-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:calls:recordings:remove --account-sid --call-sid --sid --profile --cli-log-level --cli-output-format
api:core:calls:update --account-sid --sid --fallback-method --fallback-url --method --status --status-callback --status-callback-method --twiml --url --properties --profile --cli-log-level --cli-output-format
api:core:calls:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:calls:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:conferences:list --account-sid --date-created --date-created-before --date-created-after --date-updated --date-updated-before --date-updated-after --friendly-name --status --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:conferences:participants:create --account-sid --conference-sid --beep --byoc --call-sid-to-coach --caller-id --coaching --conference-record --conference-recording-status-callback --conference-recording-status-callback-event --conference-recording-status-callback-method --conference-status-callback --conference-status-callback-event --conference-status-callback-method --conference-trim --early-media --end-conference-on-exit --from --jitter-buffer-size --label --max-participants --muted --record --recording-channels --recording-status-callback --recording-status-callback-event --recording-status-callback-method --region --sip-auth-password --sip-auth-username --start-conference-on-enter --status-callback --status-callback-event --status-callback-method --timeout --to --wait-method --wait-url --properties --profile --cli-log-level --cli-output-format
api:core:conferences:participants:list --account-sid --conference-sid --muted --hold --coaching --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:conferences:participants:update --account-sid --conference-sid --call-sid --announce-method --announce-url --beep-on-exit --call-sid-to-coach --coaching --end-conference-on-exit --hold --hold-method --hold-url --muted --wait-method --wait-url --properties --profile --cli-log-level --cli-output-format
api:core:conferences:participants:fetch --account-sid --conference-sid --call-sid --properties --profile --cli-log-level --cli-output-format
api:core:conferences:participants:remove --account-sid --conference-sid --call-sid --profile --cli-log-level --cli-output-format
api:core:conferences:recordings:list --account-sid --conference-sid --date-created --date-created-before --date-created-after --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:conferences:recordings:update --account-sid --conference-sid --sid --pause-behavior --status --properties --profile --cli-log-level --cli-output-format
api:core:conferences:recordings:fetch --account-sid --conference-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:conferences:recordings:remove --account-sid --conference-sid --sid --profile --cli-log-level --cli-output-format
api:core:conferences:update --account-sid --sid --announce-method --announce-url --status --properties --profile --cli-log-level --cli-output-format
api:core:conferences:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:connect-apps:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:connect-apps:update --account-sid --sid --authorize-redirect-url --company-name --deauthorize-callback-method --deauthorize-callback-url --description --friendly-name --homepage-url --permissions --properties --profile --cli-log-level --cli-output-format
api:core:connect-apps:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:connect-apps:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:create --account-sid --address-sid --api-version --area-code --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --phone-number --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:list --account-sid --beta --friendly-name --phone-number --origin --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:local:create --account-sid --address-sid --api-version --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --phone-number --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:local:list --account-sid --beta --friendly-name --phone-number --origin --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:mobile:create --account-sid --address-sid --api-version --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --phone-number --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:mobile:list --account-sid --beta --friendly-name --phone-number --origin --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:toll-free:create --account-sid --address-sid --api-version --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --phone-number --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:toll-free:list --account-sid --beta --friendly-name --phone-number --origin --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:assigned-add-ons:create --account-sid --resource-sid --installed-add-on-sid --properties --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:assigned-add-ons:list --account-sid --resource-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:assigned-add-ons:extensions:list --account-sid --resource-sid --assigned-add-on-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:assigned-add-ons:extensions:fetch --account-sid --resource-sid --assigned-add-on-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:assigned-add-ons:fetch --account-sid --resource-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:assigned-add-ons:remove --account-sid --resource-sid --sid --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:update --account-sid --sid --target-account-sid --address-sid --api-version --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:incoming-phone-numbers:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:keys:create --account-sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:keys:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:keys:update --account-sid --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:keys:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:keys:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:messages:create --account-sid --address-retention --application-sid --attempt --body --content-retention --force-delivery --from --max-price --media-url --messaging-service-sid --persistent-action --provide-feedback --smart-encoded --status-callback --to --validity-period --properties --profile --cli-log-level --cli-output-format
api:core:messages:list --account-sid --to --from --date-sent --date-sent-before --date-sent-after --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:messages:feedback:create --account-sid --message-sid --outcome --properties --profile --cli-log-level --cli-output-format
api:core:messages:media:list --account-sid --message-sid --date-created --date-created-before --date-created-after --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:messages:media:fetch --account-sid --message-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:messages:media:remove --account-sid --message-sid --sid --profile --cli-log-level --cli-output-format
api:core:messages:update --account-sid --sid --body --properties --profile --cli-log-level --cli-output-format
api:core:messages:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:messages:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:notifications:list --account-sid --log --message-date --message-date-before --message-date-after --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:notifications:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:outgoing-caller-ids:create --account-sid --call-delay --extension --friendly-name --phone-number --status-callback --status-callback-method --properties --profile --cli-log-level --cli-output-format
api:core:outgoing-caller-ids:list --account-sid --phone-number --friendly-name --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:outgoing-caller-ids:update --account-sid --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:outgoing-caller-ids:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:outgoing-caller-ids:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:queues:create --account-sid --friendly-name --max-size --properties --profile --cli-log-level --cli-output-format
api:core:queues:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:queues:members:list --account-sid --queue-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:queues:members:update --account-sid --queue-sid --call-sid --method --url --properties --profile --cli-log-level --cli-output-format
api:core:queues:members:fetch --account-sid --queue-sid --call-sid --properties --profile --cli-log-level --cli-output-format
api:core:queues:update --account-sid --sid --friendly-name --max-size --properties --profile --cli-log-level --cli-output-format
api:core:queues:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:queues:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:recordings:list --account-sid --date-created --date-created-before --date-created-after --call-sid --conference-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:recordings:transcriptions:list --account-sid --recording-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:recordings:transcriptions:fetch --account-sid --recording-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:recordings:transcriptions:remove --account-sid --recording-sid --sid --profile --cli-log-level --cli-output-format
api:core:recordings:add-on-results:list --account-sid --reference-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:recordings:add-on-results:payloads:list --account-sid --reference-sid --add-on-result-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:recordings:add-on-results:payloads:fetch --account-sid --reference-sid --add-on-result-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:recordings:add-on-results:payloads:remove --account-sid --reference-sid --add-on-result-sid --sid --profile --cli-log-level --cli-output-format
api:core:recordings:add-on-results:fetch --account-sid --reference-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:recordings:add-on-results:remove --account-sid --reference-sid --sid --profile --cli-log-level --cli-output-format
api:core:recordings:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:recordings:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:create --account-sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:credentials:create --account-sid --credential-list-sid --password --username --properties --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:credentials:list --account-sid --credential-list-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:credentials:update --account-sid --credential-list-sid --sid --password --properties --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:credentials:fetch --account-sid --credential-list-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:credentials:remove --account-sid --credential-list-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:update --account-sid --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:credential-lists:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:domains:create --account-sid --byoc-trunk-sid --domain-name --emergency-caller-sid --emergency-calling-enabled --friendly-name --secure --sip-registration --voice-fallback-method --voice-fallback-url --voice-method --voice-status-callback-method --voice-status-callback-url --voice-url --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:calls:credential-list-mappings:create --account-sid --domain-sid --credential-list-sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:calls:credential-list-mappings:list --account-sid --domain-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:calls:credential-list-mappings:fetch --account-sid --domain-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:calls:credential-list-mappings:remove --account-sid --domain-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:calls:ip-access-control-list-mappings:create --account-sid --domain-sid --ip-access-control-list-sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:calls:ip-access-control-list-mappings:list --account-sid --domain-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:calls:ip-access-control-list-mappings:fetch --account-sid --domain-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:calls:ip-access-control-list-mappings:remove --account-sid --domain-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:registrations:credential-list-mappings:create --account-sid --domain-sid --credential-list-sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:registrations:credential-list-mappings:list --account-sid --domain-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:registrations:credential-list-mappings:fetch --account-sid --domain-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:auth:registrations:credential-list-mappings:remove --account-sid --domain-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:domains:credential-list-mappings:create --account-sid --domain-sid --credential-list-sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:credential-list-mappings:list --account-sid --domain-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:domains:credential-list-mappings:fetch --account-sid --domain-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:credential-list-mappings:remove --account-sid --domain-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:domains:ip-access-control-list-mappings:create --account-sid --domain-sid --ip-access-control-list-sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:ip-access-control-list-mappings:list --account-sid --domain-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:domains:ip-access-control-list-mappings:fetch --account-sid --domain-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:ip-access-control-list-mappings:remove --account-sid --domain-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:domains:update --account-sid --sid --byoc-trunk-sid --domain-name --emergency-caller-sid --emergency-calling-enabled --friendly-name --secure --sip-registration --voice-fallback-method --voice-fallback-url --voice-method --voice-status-callback-method --voice-status-callback-url --voice-url --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:domains:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:create --account-sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:ip-addresses:create --account-sid --ip-access-control-list-sid --cidr-prefix-length --friendly-name --ip-address --properties --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:ip-addresses:list --account-sid --ip-access-control-list-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:ip-addresses:update --account-sid --ip-access-control-list-sid --sid --cidr-prefix-length --friendly-name --ip-address --properties --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:ip-addresses:fetch --account-sid --ip-access-control-list-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:ip-addresses:remove --account-sid --ip-access-control-list-sid --sid --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:update --account-sid --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:sip:ip-access-control-lists:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:sms:short-codes:list --account-sid --friendly-name --short-code --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:sms:short-codes:update --account-sid --sid --api-version --friendly-name --sms-fallback-method --sms-fallback-url --sms-method --sms-url --properties --profile --cli-log-level --cli-output-format
api:core:sms:short-codes:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:signing-keys:create --account-sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:signing-keys:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:signing-keys:update --account-sid --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:signing-keys:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:signing-keys:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:tokens:create --account-sid --ttl --properties --profile --cli-log-level --cli-output-format
api:core:transcriptions:list --account-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:transcriptions:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:transcriptions:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:usage:records:list --account-sid --category --start-date --end-date --include-subaccounts --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:records:all-time:list --account-sid --category --start-date --end-date --include-subaccounts --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:records:daily:list --account-sid --category --start-date --end-date --include-subaccounts --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:records:last-month:list --account-sid --category --start-date --end-date --include-subaccounts --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:records:monthly:list --account-sid --category --start-date --end-date --include-subaccounts --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:records:this-month:list --account-sid --category --start-date --end-date --include-subaccounts --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:records:today:list --account-sid --category --start-date --end-date --include-subaccounts --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:records:yearly:list --account-sid --category --start-date --end-date --include-subaccounts --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:records:yesterday:list --account-sid --category --start-date --end-date --include-subaccounts --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:triggers:create --account-sid --callback-method --callback-url --friendly-name --recurring --trigger-by --trigger-value --usage-category --properties --profile --cli-log-level --cli-output-format
api:core:usage:triggers:list --account-sid --recurring --trigger-by --usage-category --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:core:usage:triggers:update --account-sid --sid --callback-method --callback-url --friendly-name --properties --profile --cli-log-level --cli-output-format
api:core:usage:triggers:fetch --account-sid --sid --properties --profile --cli-log-level --cli-output-format
api:core:usage:triggers:remove --account-sid --sid --profile --cli-log-level --cli-output-format
api:core:accounts:update --sid --friendly-name --status --properties --profile --cli-log-level --cli-output-format
api:core:accounts:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:create --callback-events --callback-url --defaults --friendly-name --log-queries --style-sheet --unique-name --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:restore:create --assistant --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:defaults:update --assistant-sid --defaults --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:defaults:fetch --assistant-sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:dialogues:fetch --assistant-sid --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:field-types:create --assistant-sid --friendly-name --unique-name --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:field-types:list --assistant-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:field-types:field-values:create --assistant-sid --field-type-sid --language --synonym-of --value --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:field-types:field-values:list --assistant-sid --field-type-sid --language --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:field-types:field-values:fetch --assistant-sid --field-type-sid --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:field-types:field-values:remove --assistant-sid --field-type-sid --sid --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:field-types:update --assistant-sid --sid --friendly-name --unique-name --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:field-types:fetch --assistant-sid --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:field-types:remove --assistant-sid --sid --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:model-builds:create --assistant-sid --status-callback --unique-name --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:model-builds:list --assistant-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:model-builds:update --assistant-sid --sid --unique-name --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:model-builds:fetch --assistant-sid --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:model-builds:remove --assistant-sid --sid --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:queries:create --assistant-sid --language --model-build --query --tasks --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:queries:list --assistant-sid --language --model-build --status --dialogue-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:queries:update --assistant-sid --sid --sample-sid --status --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:queries:fetch --assistant-sid --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:queries:remove --assistant-sid --sid --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:style-sheet:update --assistant-sid --style-sheet --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:style-sheet:fetch --assistant-sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:create --assistant-sid --actions --actions-url --friendly-name --unique-name --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:list --assistant-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:update --assistant-sid --sid --actions --actions-url --friendly-name --unique-name --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:fetch --assistant-sid --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:remove --assistant-sid --sid --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:actions:update --assistant-sid --task-sid --actions --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:actions:fetch --assistant-sid --task-sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:fields:create --assistant-sid --task-sid --field-type --unique-name --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:fields:list --assistant-sid --task-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:fields:fetch --assistant-sid --task-sid --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:fields:remove --assistant-sid --task-sid --sid --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:samples:create --assistant-sid --task-sid --language --source-channel --tagged-text --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:samples:list --assistant-sid --task-sid --language --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:samples:update --assistant-sid --task-sid --sid --language --source-channel --tagged-text --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:samples:fetch --assistant-sid --task-sid --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:samples:remove --assistant-sid --task-sid --sid --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:tasks:statistics:fetch --assistant-sid --task-sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:webhooks:create --assistant-sid --events --unique-name --webhook-method --webhook-url --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:webhooks:list --assistant-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:webhooks:update --assistant-sid --sid --events --unique-name --webhook-method --webhook-url --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:webhooks:fetch --assistant-sid --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:webhooks:remove --assistant-sid --sid --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:update --sid --callback-events --callback-url --defaults --development-stage --friendly-name --log-queries --style-sheet --unique-name --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:autopilot:v1:assistants:remove --sid --profile --cli-log-level --cli-output-format
api:bulkexports:v1:exports:jobs:fetch --job-sid --properties --profile --cli-log-level --cli-output-format
api:bulkexports:v1:exports:jobs:remove --job-sid --profile --cli-log-level --cli-output-format
api:bulkexports:v1:exports:fetch --resource-type --properties --profile --cli-log-level --cli-output-format
api:bulkexports:v1:exports:configuration:update --resource-type --enabled --webhook-method --webhook-url --properties --profile --cli-log-level --cli-output-format
api:bulkexports:v1:exports:configuration:fetch --resource-type --properties --profile --cli-log-level --cli-output-format
api:bulkexports:v1:exports:days:list --resource-type --next-token --previous-token --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:bulkexports:v1:exports:days:fetch --resource-type --day --properties --profile --cli-log-level --cli-output-format
api:bulkexports:v1:exports:jobs:create --resource-type --email --end-day --friendly-name --start-day --webhook-method --webhook-url --properties --profile --cli-log-level --cli-output-format
api:bulkexports:v1:exports:jobs:list --resource-type --next-token --previous-token --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:credentials:create --api-key --certificate --friendly-name --private-key --sandbox --secret --type --properties --profile --cli-log-level --cli-output-format
api:chat:v1:credentials:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:credentials:update --sid --api-key --certificate --friendly-name --private-key --sandbox --secret --properties --profile --cli-log-level --cli-output-format
api:chat:v1:credentials:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:credentials:remove --sid --profile --cli-log-level --cli-output-format
api:chat:v1:services:create --friendly-name --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:create --service-sid --attributes --friendly-name --type --unique-name --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:list --service-sid --type --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:invites:create --service-sid --channel-sid --identity --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:invites:list --service-sid --channel-sid --identity --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:invites:fetch --service-sid --channel-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:invites:remove --service-sid --channel-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:members:create --service-sid --channel-sid --identity --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:members:list --service-sid --channel-sid --identity --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:members:update --service-sid --channel-sid --sid --last-consumed-message-index --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:members:fetch --service-sid --channel-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:members:remove --service-sid --channel-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:messages:create --service-sid --channel-sid --attributes --body --from --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:messages:list --service-sid --channel-sid --order --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:messages:update --service-sid --channel-sid --sid --attributes --body --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:messages:fetch --service-sid --channel-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:messages:remove --service-sid --channel-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:update --service-sid --sid --attributes --friendly-name --unique-name --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:channels:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v1:services:roles:create --service-sid --friendly-name --permission --type --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:roles:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:services:roles:update --service-sid --sid --permission --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:roles:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:roles:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v1:services:users:create --service-sid --attributes --friendly-name --identity --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:users:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:services:users:update --service-sid --sid --attributes --friendly-name --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:users:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:users:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v1:services:users:channels:list --service-sid --user-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v1:services:update --sid --consumption-report-interval --default-channel-creator-role-sid --default-channel-role-sid --default-service-role-sid --friendly-name --limits.channel-members --limits.user-channels --notifications.added-to-channel.enabled --notifications.added-to-channel.template --notifications.invited-to-channel.enabled --notifications.invited-to-channel.template --notifications.new-message.enabled --notifications.new-message.template --notifications.removed-from-channel.enabled --notifications.removed-from-channel.template --post-webhook-url --pre-webhook-url --reachability-enabled --read-status-enabled --typing-indicator-timeout --webhook-filters --webhook-method --webhooks.on-channel-add.method --webhooks.on-channel-add.url --webhooks.on-channel-added.method --webhooks.on-channel-added.url --webhooks.on-channel-destroy.method --webhooks.on-channel-destroy.url --webhooks.on-channel-destroyed.method --webhooks.on-channel-destroyed.url --webhooks.on-channel-update.method --webhooks.on-channel-update.url --webhooks.on-channel-updated.method --webhooks.on-channel-updated.url --webhooks.on-member-add.method --webhooks.on-member-add.url --webhooks.on-member-added.method --webhooks.on-member-added.url --webhooks.on-member-remove.method --webhooks.on-member-remove.url --webhooks.on-member-removed.method --webhooks.on-member-removed.url --webhooks.on-message-remove.method --webhooks.on-message-remove.url --webhooks.on-message-removed.method --webhooks.on-message-removed.url --webhooks.on-message-send.method --webhooks.on-message-send.url --webhooks.on-message-sent.method --webhooks.on-message-sent.url --webhooks.on-message-update.method --webhooks.on-message-update.url --webhooks.on-message-updated.method --webhooks.on-message-updated.url --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v1:services:remove --sid --profile --cli-log-level --cli-output-format
api:chat:v2:credentials:create --api-key --certificate --friendly-name --private-key --sandbox --secret --type --properties --profile --cli-log-level --cli-output-format
api:chat:v2:credentials:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:credentials:update --sid --api-key --certificate --friendly-name --private-key --sandbox --secret --properties --profile --cli-log-level --cli-output-format
api:chat:v2:credentials:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:credentials:remove --sid --profile --cli-log-level --cli-output-format
api:chat:v2:services:create --friendly-name --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:bindings:list --service-sid --binding-type --identity --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:bindings:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:bindings:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:create --service-sid --x-twilio-webhook-enabled --attributes --created-by --date-created --date-updated --friendly-name --type --unique-name --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:list --service-sid --type --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:invites:create --service-sid --channel-sid --identity --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:invites:list --service-sid --channel-sid --identity --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:invites:fetch --service-sid --channel-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:invites:remove --service-sid --channel-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:members:create --service-sid --channel-sid --x-twilio-webhook-enabled --attributes --date-created --date-updated --identity --last-consumed-message-index --last-consumption-timestamp --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:members:list --service-sid --channel-sid --identity --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:members:update --service-sid --channel-sid --sid --x-twilio-webhook-enabled --attributes --date-created --date-updated --last-consumed-message-index --last-consumption-timestamp --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:members:fetch --service-sid --channel-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:members:remove --service-sid --channel-sid --sid --x-twilio-webhook-enabled --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:messages:create --service-sid --channel-sid --x-twilio-webhook-enabled --attributes --body --date-created --date-updated --from --last-updated-by --media-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:messages:list --service-sid --channel-sid --order --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:messages:update --service-sid --channel-sid --sid --x-twilio-webhook-enabled --attributes --body --date-created --date-updated --from --last-updated-by --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:messages:fetch --service-sid --channel-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:messages:remove --service-sid --channel-sid --sid --x-twilio-webhook-enabled --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:webhooks:create --service-sid --channel-sid --configuration.filters --configuration.flow-sid --configuration.method --configuration.retry-count --configuration.triggers --configuration.url --type --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:webhooks:list --service-sid --channel-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:webhooks:update --service-sid --channel-sid --sid --configuration.filters --configuration.flow-sid --configuration.method --configuration.retry-count --configuration.triggers --configuration.url --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:webhooks:fetch --service-sid --channel-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:webhooks:remove --service-sid --channel-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:update --service-sid --sid --x-twilio-webhook-enabled --attributes --created-by --date-created --date-updated --friendly-name --unique-name --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:channels:remove --service-sid --sid --x-twilio-webhook-enabled --profile --cli-log-level --cli-output-format
api:chat:v2:services:roles:create --service-sid --friendly-name --permission --type --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:roles:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:roles:update --service-sid --sid --permission --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:roles:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:roles:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:create --service-sid --x-twilio-webhook-enabled --attributes --friendly-name --identity --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:update --service-sid --sid --x-twilio-webhook-enabled --attributes --friendly-name --role-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:bindings:list --service-sid --user-sid --binding-type --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:bindings:fetch --service-sid --user-sid --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:bindings:remove --service-sid --user-sid --sid --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:channels:list --service-sid --user-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:channels:update --service-sid --user-sid --channel-sid --last-consumed-message-index --last-consumption-timestamp --notification-level --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:channels:fetch --service-sid --user-sid --channel-sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:users:channels:remove --service-sid --user-sid --channel-sid --profile --cli-log-level --cli-output-format
api:chat:v2:services:update --sid --consumption-report-interval --default-channel-creator-role-sid --default-channel-role-sid --default-service-role-sid --friendly-name --limits.channel-members --limits.user-channels --media.compatibility-message --notifications.added-to-channel.enabled --notifications.added-to-channel.sound --notifications.added-to-channel.template --notifications.invited-to-channel.enabled --notifications.invited-to-channel.sound --notifications.invited-to-channel.template --notifications.log-enabled --notifications.new-message.badge-count-enabled --notifications.new-message.enabled --notifications.new-message.sound --notifications.new-message.template --notifications.removed-from-channel.enabled --notifications.removed-from-channel.sound --notifications.removed-from-channel.template --post-webhook-retry-count --post-webhook-url --pre-webhook-retry-count --pre-webhook-url --reachability-enabled --read-status-enabled --typing-indicator-timeout --webhook-filters --webhook-method --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:chat:v2:services:remove --sid --profile --cli-log-level --cli-output-format
api:conversations:v1:configuration:update --default-chat-service-sid --default-closed-timer --default-inactive-timer --default-messaging-service-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:configuration:fetch --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:configuration:webhooks:update --filters --method --post-webhook-url --pre-webhook-url --target --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:configuration:webhooks:fetch --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:create --x-twilio-webhook-enabled --attributes --date-created --date-updated --friendly-name --messaging-service-sid --state --timers.closed --timers.inactive --unique-name --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:messages:create --conversation-sid --x-twilio-webhook-enabled --attributes --author --body --date-created --date-updated --media-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:messages:list --conversation-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:messages:receipts:list --conversation-sid --message-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:messages:receipts:fetch --conversation-sid --message-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:messages:update --conversation-sid --sid --x-twilio-webhook-enabled --attributes --author --body --date-created --date-updated --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:messages:fetch --conversation-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:messages:remove --conversation-sid --sid --x-twilio-webhook-enabled --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:participants:create --conversation-sid --x-twilio-webhook-enabled --attributes --date-created --date-updated --identity --messaging-binding.address --messaging-binding.projected-address --messaging-binding.proxy-address --role-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:participants:list --conversation-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:participants:update --conversation-sid --sid --x-twilio-webhook-enabled --attributes --date-created --date-updated --identity --messaging-binding.projected-address --messaging-binding.proxy-address --role-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:participants:fetch --conversation-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:participants:remove --conversation-sid --sid --x-twilio-webhook-enabled --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:webhooks:create --conversation-sid --configuration.filters --configuration.flow-sid --configuration.method --configuration.replay-after --configuration.triggers --configuration.url --target --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:webhooks:list --conversation-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:webhooks:update --conversation-sid --sid --configuration.filters --configuration.flow-sid --configuration.method --configuration.triggers --configuration.url --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:webhooks:fetch --conversation-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:webhooks:remove --conversation-sid --sid --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:update --sid --x-twilio-webhook-enabled --attributes --date-created --date-updated --friendly-name --messaging-service-sid --state --timers.closed --timers.inactive --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:conversations:remove --sid --x-twilio-webhook-enabled --profile --cli-log-level --cli-output-format
api:conversations:v1:credentials:create --api-key --certificate --friendly-name --private-key --sandbox --secret --type --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:credentials:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:credentials:update --sid --api-key --certificate --friendly-name --private-key --sandbox --secret --type --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:credentials:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:credentials:remove --sid --profile --cli-log-level --cli-output-format
api:conversations:v1:roles:create --friendly-name --permission --type --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:roles:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:roles:update --sid --permission --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:roles:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:roles:remove --sid --profile --cli-log-level --cli-output-format
api:conversations:v1:services:create --friendly-name --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:services:bindings:list --chat-service-sid --binding-type --identity --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:services:bindings:fetch --chat-service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:bindings:remove --chat-service-sid --sid --profile --cli-log-level --cli-output-format
api:conversations:v1:services:configuration:update --chat-service-sid --default-chat-service-role-sid --default-conversation-creator-role-sid --default-conversation-role-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:configuration:fetch --chat-service-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:configuration:notifications:update --chat-service-sid --added-to-conversation.enabled --added-to-conversation.sound --added-to-conversation.template --log-enabled --new-message.badge-count-enabled --new-message.enabled --new-message.sound --new-message.template --removed-from-conversation.enabled --removed-from-conversation.sound --removed-from-conversation.template --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:configuration:notifications:fetch --chat-service-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:create --chat-service-sid --x-twilio-webhook-enabled --attributes --date-created --date-updated --friendly-name --messaging-service-sid --state --timers.closed --timers.inactive --unique-name --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:list --chat-service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:messages:create --chat-service-sid --conversation-sid --x-twilio-webhook-enabled --attributes --author --body --date-created --date-updated --media-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:messages:list --chat-service-sid --conversation-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:messages:receipts:list --chat-service-sid --conversation-sid --message-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:messages:receipts:fetch --chat-service-sid --conversation-sid --message-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:messages:update --chat-service-sid --conversation-sid --sid --x-twilio-webhook-enabled --attributes --author --body --date-created --date-updated --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:messages:fetch --chat-service-sid --conversation-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:messages:remove --chat-service-sid --conversation-sid --sid --x-twilio-webhook-enabled --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:participants:create --chat-service-sid --conversation-sid --x-twilio-webhook-enabled --attributes --date-created --date-updated --identity --messaging-binding.address --messaging-binding.projected-address --messaging-binding.proxy-address --role-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:participants:list --chat-service-sid --conversation-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:participants:update --chat-service-sid --conversation-sid --sid --x-twilio-webhook-enabled --attributes --date-created --date-updated --identity --messaging-binding.projected-address --messaging-binding.proxy-address --role-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:participants:fetch --chat-service-sid --conversation-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:participants:remove --chat-service-sid --conversation-sid --sid --x-twilio-webhook-enabled --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:webhooks:create --chat-service-sid --conversation-sid --configuration.filters --configuration.flow-sid --configuration.method --configuration.replay-after --configuration.triggers --configuration.url --target --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:webhooks:list --chat-service-sid --conversation-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:webhooks:update --chat-service-sid --conversation-sid --sid --configuration.filters --configuration.flow-sid --configuration.method --configuration.triggers --configuration.url --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:webhooks:fetch --chat-service-sid --conversation-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:webhooks:remove --chat-service-sid --conversation-sid --sid --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:update --chat-service-sid --sid --x-twilio-webhook-enabled --attributes --date-created --date-updated --friendly-name --messaging-service-sid --state --timers.closed --timers.inactive --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:fetch --chat-service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:conversations:remove --chat-service-sid --sid --x-twilio-webhook-enabled --profile --cli-log-level --cli-output-format
api:conversations:v1:services:roles:create --chat-service-sid --friendly-name --permission --type --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:roles:list --chat-service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:services:roles:update --chat-service-sid --sid --permission --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:roles:fetch --chat-service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:roles:remove --chat-service-sid --sid --profile --cli-log-level --cli-output-format
api:conversations:v1:services:users:create --chat-service-sid --attributes --friendly-name --identity --role-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:users:list --chat-service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:services:users:update --chat-service-sid --sid --attributes --friendly-name --role-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:users:fetch --chat-service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:users:remove --chat-service-sid --sid --profile --cli-log-level --cli-output-format
api:conversations:v1:services:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:services:remove --sid --profile --cli-log-level --cli-output-format
api:conversations:v1:users:create --attributes --friendly-name --identity --role-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:users:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:conversations:v1:users:update --sid --attributes --friendly-name --role-sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:users:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:conversations:v1:users:remove --sid --profile --cli-log-level --cli-output-format
api:events:v1:schemas:fetch --id --properties --profile --cli-log-level --cli-output-format
api:events:v1:schemas:versions:list --id --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:events:v1:schemas:versions:fetch --id --schema-version --properties --profile --cli-log-level --cli-output-format
api:events:v1:sinks:create --description --sink-configuration --sink-type --properties --profile --cli-log-level --cli-output-format
api:events:v1:sinks:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:events:v1:sinks:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:events:v1:sinks:remove --sid --profile --cli-log-level --cli-output-format
api:events:v1:sinks:test:create --sid --properties --profile --cli-log-level --cli-output-format
api:events:v1:sinks:validate:create --sid --test-id --properties --profile --cli-log-level --cli-output-format
api:events:v1:subscriptions:create --description --sink-sid --types --properties --profile --cli-log-level --cli-output-format
api:events:v1:subscriptions:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:events:v1:subscriptions:update --sid --description --sink-sid --properties --profile --cli-log-level --cli-output-format
api:events:v1:subscriptions:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:events:v1:subscriptions:remove --sid --profile --cli-log-level --cli-output-format
api:events:v1:subscriptions:subscribed-events:list --subscription-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:events:v1:types:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:events:v1:types:fetch --type --properties --profile --cli-log-level --cli-output-format
api:fax:v1:faxes:create --from --media-url --quality --sip-auth-password --sip-auth-username --status-callback --store-media --to --ttl --properties --profile --cli-log-level --cli-output-format
api:fax:v1:faxes:list --from --to --date-created-on-or-before --date-created-after --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:fax:v1:faxes:media:list --fax-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:fax:v1:faxes:media:fetch --fax-sid --sid --properties --profile --cli-log-level --cli-output-format
api:fax:v1:faxes:media:remove --fax-sid --sid --profile --cli-log-level --cli-output-format
api:fax:v1:faxes:update --sid --status --properties --profile --cli-log-level --cli-output-format
api:fax:v1:faxes:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:fax:v1:faxes:remove --sid --profile --cli-log-level --cli-output-format
api:flex:v1:channels:create --chat-friendly-name --chat-unique-name --chat-user-friendly-name --flex-flow-sid --identity --long-lived --pre-engagement-data --target --task-attributes --task-sid --properties --profile --cli-log-level --cli-output-format
api:flex:v1:channels:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:flex:v1:channels:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:flex:v1:channels:remove --sid --profile --cli-log-level --cli-output-format
api:flex:v1:configuration:update --properties --profile --cli-log-level --cli-output-format
api:flex:v1:configuration:fetch --ui-version --properties --profile --cli-log-level --cli-output-format
api:flex:v1:flex-flows:create --channel-type --chat-service-sid --contact-identity --enabled --friendly-name --integration.channel --integration.creation-on-message --integration.flow-sid --integration.priority --integration.retry-count --integration.timeout --integration.url --integration.workflow-sid --integration.workspace-sid --integration-type --janitor-enabled --long-lived --properties --profile --cli-log-level --cli-output-format
api:flex:v1:flex-flows:list --friendly-name --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:flex:v1:flex-flows:update --sid --channel-type --chat-service-sid --contact-identity --enabled --friendly-name --integration.channel --integration.creation-on-message --integration.flow-sid --integration.priority --integration.retry-count --integration.timeout --integration.url --integration.workflow-sid --integration.workspace-sid --integration-type --janitor-enabled --long-lived --properties --profile --cli-log-level --cli-output-format
api:flex:v1:flex-flows:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:flex:v1:flex-flows:remove --sid --profile --cli-log-level --cli-output-format
api:flex:v1:web-channels:create --chat-friendly-name --chat-unique-name --customer-friendly-name --flex-flow-sid --identity --pre-engagement-data --properties --profile --cli-log-level --cli-output-format
api:flex:v1:web-channels:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:flex:v1:web-channels:update --sid --chat-status --post-engagement-data --properties --profile --cli-log-level --cli-output-format
api:flex:v1:web-channels:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:flex:v1:web-channels:remove --sid --profile --cli-log-level --cli-output-format
api:insights:v1:voice:events:list --call-sid --edge --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:insights:v1:voice:metrics:list --call-sid --edge --direction --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:insights:v1:voice:summary:fetch --call-sid --processing-state --properties --profile --cli-log-level --cli-output-format
api:insights:v1:voice:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:lookups:v1:phone-numbers:fetch --phone-number --country-code --type --add-ons --add-ons-data --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:deactivations:fetch --date --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:create --area-code-geomatch --fallback-method --fallback-to-long-code --fallback-url --friendly-name --inbound-method --inbound-request-url --mms-converter --scan-message-content --smart-encoding --status-callback --sticky-sender --synchronous-validation --validity-period --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:messaging:v1:services:alpha-senders:create --service-sid --alpha-sender --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:alpha-senders:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:messaging:v1:services:alpha-senders:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:alpha-senders:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:messaging:v1:services:phone-numbers:create --service-sid --phone-number-sid --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:phone-numbers:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:messaging:v1:services:phone-numbers:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:phone-numbers:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:messaging:v1:services:short-codes:create --service-sid --short-code-sid --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:short-codes:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:messaging:v1:services:short-codes:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:short-codes:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:messaging:v1:services:update --sid --area-code-geomatch --fallback-method --fallback-to-long-code --fallback-url --friendly-name --inbound-method --inbound-request-url --mms-converter --scan-message-content --smart-encoding --status-callback --sticky-sender --synchronous-validation --validity-period --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:messaging:v1:services:remove --sid --profile --cli-log-level --cli-output-format
api:monitor:v1:alerts:list --log-level --start-date --end-date --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:monitor:v1:alerts:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:monitor:v1:events:list --actor-sid --event-type --resource-sid --source-ip-address --start-date --end-date --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:monitor:v1:events:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:notify:v1:credentials:create --api-key --certificate --friendly-name --private-key --sandbox --secret --type --properties --profile --cli-log-level --cli-output-format
api:notify:v1:credentials:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:notify:v1:credentials:update --sid --api-key --certificate --friendly-name --private-key --sandbox --secret --properties --profile --cli-log-level --cli-output-format
api:notify:v1:credentials:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:notify:v1:credentials:remove --sid --profile --cli-log-level --cli-output-format
api:notify:v1:services:create --alexa-skill-id --apn-credential-sid --default-alexa-notification-protocol-version --default-apn-notification-protocol-version --default-fcm-notification-protocol-version --default-gcm-notification-protocol-version --delivery-callback-enabled --delivery-callback-url --facebook-messenger-page-id --fcm-credential-sid --friendly-name --gcm-credential-sid --log-enabled --messaging-service-sid --properties --profile --cli-log-level --cli-output-format
api:notify:v1:services:list --friendly-name --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:notify:v1:services:bindings:create --service-sid --address --binding-type --credential-sid --endpoint --identity --notification-protocol-version --tag --properties --profile --cli-log-level --cli-output-format
api:notify:v1:services:bindings:list --service-sid --start-date --end-date --identity --tag --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:notify:v1:services:bindings:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:notify:v1:services:bindings:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:notify:v1:services:notifications:create --service-sid --action --alexa --apn --body --data --delivery-callback-url --facebook-messenger --fcm --gcm --identity --priority --segment --sms --sound --tag --title --to-binding --ttl --properties --profile --cli-log-level --cli-output-format
api:notify:v1:services:update --sid --alexa-skill-id --apn-credential-sid --default-alexa-notification-protocol-version --default-apn-notification-protocol-version --default-fcm-notification-protocol-version --default-gcm-notification-protocol-version --delivery-callback-enabled --delivery-callback-url --facebook-messenger-page-id --fcm-credential-sid --friendly-name --gcm-credential-sid --log-enabled --messaging-service-sid --properties --profile --cli-log-level --cli-output-format
api:notify:v1:services:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:notify:v1:services:remove --sid --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:create --email --end-user-type --friendly-name --iso-country --number-type --regulation-sid --status-callback --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:list --status --friendly-name --regulation-sid --iso-country --number-type --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:evaluations:create --bundle-sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:evaluations:list --bundle-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:evaluations:fetch --bundle-sid --sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:item-assignments:create --bundle-sid --object-sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:item-assignments:list --bundle-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:item-assignments:fetch --bundle-sid --sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:item-assignments:remove --bundle-sid --sid --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:update --sid --email --friendly-name --status --status-callback --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:bundles:remove --sid --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:end-user-types:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:end-user-types:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:end-users:create --attributes --friendly-name --type --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:end-users:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:end-users:update --sid --attributes --friendly-name --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:end-users:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:end-users:remove --sid --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:regulations:list --end-user-type --iso-country --number-type --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:regulations:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:supporting-document-types:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:supporting-document-types:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:supporting-documents:create --attributes --friendly-name --type --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:supporting-documents:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:supporting-documents:update --sid --attributes --friendly-name --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:supporting-documents:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:numbers:v2:regulatory-compliance:supporting-documents:remove --sid --profile --cli-log-level --cli-output-format
api:pricing:v1:messaging:countries:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:pricing:v1:messaging:countries:fetch --iso-country --properties --profile --cli-log-level --cli-output-format
api:pricing:v1:phone-numbers:countries:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:pricing:v1:phone-numbers:countries:fetch --iso-country --properties --profile --cli-log-level --cli-output-format
api:pricing:v1:voice:countries:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:pricing:v1:voice:countries:fetch --iso-country --properties --profile --cli-log-level --cli-output-format
api:pricing:v1:voice:numbers:fetch --number --properties --profile --cli-log-level --cli-output-format
api:pricing:v2:voice:countries:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:pricing:v2:voice:countries:fetch --iso-country --properties --profile --cli-log-level --cli-output-format
api:pricing:v2:voice:numbers:fetch --destination-number --origination-number --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:create --callback-url --chat-instance-sid --default-ttl --geo-match-level --intercept-callback-url --number-selection-behavior --out-of-session-callback-url --unique-name --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:proxy:v1:services:phone-numbers:create --service-sid --is-reserved --phone-number --sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:phone-numbers:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:proxy:v1:services:phone-numbers:update --service-sid --sid --is-reserved --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:phone-numbers:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:phone-numbers:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:create --service-sid --date-expiry --fail-on-participant-conflict --mode --participants --status --ttl --unique-name --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:interactions:list --service-sid --session-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:interactions:fetch --service-sid --session-sid --sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:interactions:remove --service-sid --session-sid --sid --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:participants:create --service-sid --session-sid --fail-on-participant-conflict --friendly-name --identifier --proxy-identifier --proxy-identifier-sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:participants:list --service-sid --session-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:participants:message-interactions:create --service-sid --session-sid --participant-sid --body --media-url --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:participants:message-interactions:list --service-sid --session-sid --participant-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:participants:message-interactions:fetch --service-sid --session-sid --participant-sid --sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:participants:fetch --service-sid --session-sid --sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:participants:remove --service-sid --session-sid --sid --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:update --service-sid --sid --date-expiry --fail-on-participant-conflict --status --ttl --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:sessions:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:proxy:v1:services:short-codes:create --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:short-codes:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:proxy:v1:services:short-codes:update --service-sid --sid --is-reserved --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:short-codes:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:short-codes:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:proxy:v1:services:update --sid --callback-url --chat-instance-sid --default-ttl --geo-match-level --intercept-callback-url --number-selection-behavior --out-of-session-callback-url --unique-name --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:proxy:v1:services:remove --sid --profile --cli-log-level --cli-output-format
api:serverless:v1:services:create --friendly-name --include-credentials --ui-editable --unique-name --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:assets:create --service-sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:assets:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:assets:versions:list --service-sid --asset-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:assets:versions:fetch --service-sid --asset-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:assets:update --service-sid --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:assets:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:assets:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:serverless:v1:services:builds:create --service-sid --asset-versions --dependencies --function-versions --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:builds:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:builds:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:builds:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:create --service-sid --domain-suffix --unique-name --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:deployments:create --service-sid --environment-sid --build-sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:deployments:list --service-sid --environment-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:deployments:fetch --service-sid --environment-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:logs:list --service-sid --environment-sid --function-sid --start-date --end-date --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:logs:fetch --service-sid --environment-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:variables:create --service-sid --environment-sid --key --value --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:variables:list --service-sid --environment-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:variables:update --service-sid --environment-sid --sid --key --value --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:variables:fetch --service-sid --environment-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:variables:remove --service-sid --environment-sid --sid --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:environments:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:serverless:v1:services:functions:create --service-sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:functions:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:functions:versions:list --service-sid --function-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:serverless:v1:services:functions:versions:fetch --service-sid --function-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:functions:versions:content:fetch --service-sid --function-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:functions:update --service-sid --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:functions:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:functions:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:serverless:v1:services:update --sid --friendly-name --include-credentials --ui-editable --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:serverless:v1:services:remove --sid --profile --cli-log-level --cli-output-format
api:studio:v1:flows:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:studio:v1:flows:engagements:create --flow-sid --from --parameters --to --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:engagements:list --flow-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:studio:v1:flows:engagements:context:fetch --flow-sid --engagement-sid --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:engagements:steps:list --flow-sid --engagement-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:studio:v1:flows:engagements:steps:fetch --flow-sid --engagement-sid --sid --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:engagements:steps:context:fetch --flow-sid --engagement-sid --step-sid --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:engagements:fetch --flow-sid --sid --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:engagements:remove --flow-sid --sid --profile --cli-log-level --cli-output-format
api:studio:v1:flows:executions:create --flow-sid --from --parameters --to --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:executions:list --flow-sid --date-created-from --date-created-to --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:studio:v1:flows:executions:context:fetch --flow-sid --execution-sid --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:executions:steps:list --flow-sid --execution-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:studio:v1:flows:executions:steps:fetch --flow-sid --execution-sid --sid --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:executions:steps:context:fetch --flow-sid --execution-sid --step-sid --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:executions:update --flow-sid --sid --status --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:executions:fetch --flow-sid --sid --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:executions:remove --flow-sid --sid --profile --cli-log-level --cli-output-format
api:studio:v1:flows:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:studio:v1:flows:remove --sid --profile --cli-log-level --cli-output-format
api:studio:v2:flows:create --commit-message --definition --friendly-name --status --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:studio:v2:flows:validate:create --commit-message --definition --friendly-name --status --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:executions:create --flow-sid --from --parameters --to --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:executions:list --flow-sid --date-created-from --date-created-to --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:studio:v2:flows:executions:context:fetch --flow-sid --execution-sid --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:executions:steps:list --flow-sid --execution-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:studio:v2:flows:executions:steps:fetch --flow-sid --execution-sid --sid --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:executions:steps:context:fetch --flow-sid --execution-sid --step-sid --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:executions:update --flow-sid --sid --status --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:executions:fetch --flow-sid --sid --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:executions:remove --flow-sid --sid --profile --cli-log-level --cli-output-format
api:studio:v2:flows:update --sid --commit-message --definition --friendly-name --status --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:remove --sid --profile --cli-log-level --cli-output-format
api:studio:v2:flows:revisions:list --sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:studio:v2:flows:revisions:fetch --sid --revision --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:test-users:update --sid --test-users --properties --profile --cli-log-level --cli-output-format
api:studio:v2:flows:test-users:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:commands:create --callback-method --callback-url --command --sim --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:commands:list --sim --status --direction --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:supersim:v1:commands:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:fleets:create --commands-enabled --commands-method --commands-url --data-enabled --data-limit --network-access-profile --unique-name --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:fleets:list --network-access-profile --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:supersim:v1:fleets:update --sid --network-access-profile --unique-name --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:fleets:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:network-access-profiles:create --networks --unique-name --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:network-access-profiles:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:supersim:v1:network-access-profiles:networks:create --network-access-profile-sid --network --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:network-access-profiles:networks:list --network-access-profile-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:supersim:v1:network-access-profiles:networks:fetch --network-access-profile-sid --sid --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:network-access-profiles:networks:remove --network-access-profile-sid --sid --profile --cli-log-level --cli-output-format
api:supersim:v1:network-access-profiles:update --sid --unique-name --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:network-access-profiles:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:networks:list --iso-country --mcc --mnc --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:supersim:v1:networks:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:sims:list --status --fleet --iccid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:supersim:v1:sims:update --sid --account-sid --callback-method --callback-url --fleet --status --unique-name --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:sims:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:supersim:v1:usage-records:list --sim --fleet --network --iso-country --group --granularity --start-time --end-time --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:create --acl-enabled --friendly-name --reachability-debouncing-enabled --reachability-debouncing-window --reachability-webhooks-enabled --webhook-url --webhooks-from-rest-enabled --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:documents:create --service-sid --data --ttl --unique-name --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:documents:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:documents:permissions:list --service-sid --document-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:documents:permissions:update --service-sid --document-sid --identity --manage --read --write --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:documents:permissions:fetch --service-sid --document-sid --identity --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:documents:permissions:remove --service-sid --document-sid --identity --profile --cli-log-level --cli-output-format
api:sync:v1:services:documents:update --service-sid --sid --if-match --data --ttl --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:documents:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:documents:remove --service-sid --sid --if-match --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:create --service-sid --collection-ttl --ttl --unique-name --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:items:create --service-sid --list-sid --collection-ttl --data --item-ttl --ttl --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:items:list --service-sid --list-sid --order --from --bounds --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:items:update --service-sid --list-sid --index --if-match --collection-ttl --data --item-ttl --ttl --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:items:fetch --service-sid --list-sid --index --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:items:remove --service-sid --list-sid --index --if-match --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:permissions:list --service-sid --list-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:permissions:update --service-sid --list-sid --identity --manage --read --write --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:permissions:fetch --service-sid --list-sid --identity --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:permissions:remove --service-sid --list-sid --identity --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:update --service-sid --sid --collection-ttl --ttl --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:lists:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:create --service-sid --collection-ttl --ttl --unique-name --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:items:create --service-sid --map-sid --collection-ttl --data --item-ttl --key --ttl --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:items:list --service-sid --map-sid --order --from --bounds --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:items:update --service-sid --map-sid --key --if-match --collection-ttl --data --item-ttl --ttl --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:items:fetch --service-sid --map-sid --key --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:items:remove --service-sid --map-sid --key --if-match --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:permissions:list --service-sid --map-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:permissions:update --service-sid --map-sid --identity --manage --read --write --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:permissions:fetch --service-sid --map-sid --identity --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:permissions:remove --service-sid --map-sid --identity --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:update --service-sid --sid --collection-ttl --ttl --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:maps:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:sync:v1:services:streams:create --service-sid --ttl --unique-name --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:streams:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:sync:v1:services:streams:update --service-sid --sid --ttl --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:streams:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:streams:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:sync:v1:services:streams:messages:create --service-sid --stream-sid --data --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:update --sid --acl-enabled --friendly-name --reachability-debouncing-enabled --reachability-debouncing-window --reachability-webhooks-enabled --webhook-url --webhooks-from-rest-enabled --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:sync:v1:services:remove --sid --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:create --event-callback-url --events-filter --friendly-name --multi-task-enabled --prioritize-queue-order --template --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:list --friendly-name --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:update --sid --default-activity-sid --event-callback-url --events-filter --friendly-name --multi-task-enabled --prioritize-queue-order --timeout-activity-sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:remove --sid --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:activities:create --workspace-sid --available --friendly-name --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:activities:list --workspace-sid --friendly-name --available --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:activities:update --workspace-sid --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:activities:fetch --workspace-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:activities:remove --workspace-sid --sid --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:cumulative-statistics:fetch --workspace-sid --end-date --minutes --start-date --task-channel --split-by-wait-time --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:events:list --workspace-sid --end-date --event-type --minutes --reservation-sid --start-date --task-queue-sid --task-sid --worker-sid --workflow-sid --task-channel --sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:events:fetch --workspace-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:real-time-statistics:fetch --workspace-sid --task-channel --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:statistics:fetch --workspace-sid --minutes --start-date --end-date --task-channel --split-by-wait-time --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-channels:create --workspace-sid --channel-optimized-routing --friendly-name --unique-name --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-channels:list --workspace-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-channels:update --workspace-sid --sid --channel-optimized-routing --friendly-name --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-channels:fetch --workspace-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-channels:remove --workspace-sid --sid --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-queues:create --workspace-sid --assignment-activity-sid --friendly-name --max-reserved-workers --reservation-activity-sid --target-workers --task-order --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-queues:list --workspace-sid --friendly-name --evaluate-worker-attributes --worker-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-queues:statistics:list --workspace-sid --end-date --friendly-name --minutes --start-date --task-channel --split-by-wait-time --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-queues:update --workspace-sid --sid --assignment-activity-sid --friendly-name --max-reserved-workers --reservation-activity-sid --target-workers --task-order --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-queues:fetch --workspace-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-queues:remove --workspace-sid --sid --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-queues:cumulative-statistics:fetch --workspace-sid --task-queue-sid --end-date --minutes --start-date --task-channel --split-by-wait-time --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-queues:real-time-statistics:fetch --workspace-sid --task-queue-sid --task-channel --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:task-queues:statistics:fetch --workspace-sid --task-queue-sid --end-date --minutes --start-date --task-channel --split-by-wait-time --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:tasks:create --workspace-sid --attributes --priority --task-channel --timeout --workflow-sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:tasks:list --workspace-sid --priority --assignment-status --workflow-sid --workflow-name --task-queue-sid --task-queue-name --evaluate-task-attributes --ordering --has-addons --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:tasks:update --workspace-sid --sid --assignment-status --attributes --priority --reason --task-channel --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:tasks:fetch --workspace-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:tasks:remove --workspace-sid --sid --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:tasks:reservations:list --workspace-sid --task-sid --reservation-status --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:tasks:reservations:update --workspace-sid --task-sid --sid --beep --beep-on-customer-entrance --call-accept --call-from --call-record --call-status-callback-url --call-timeout --call-to --call-url --conference-record --conference-recording-status-callback --conference-recording-status-callback-method --conference-status-callback --conference-status-callback-event --conference-status-callback-method --conference-trim --dequeue-from --dequeue-post-work-activity-sid --dequeue-record --dequeue-status-callback-event --dequeue-status-callback-url --dequeue-timeout --dequeue-to --early-media --end-conference-on-customer-exit --end-conference-on-exit --from --instruction --max-participants --muted --post-work-activity-sid --record --recording-channels --recording-status-callback --recording-status-callback-method --redirect-accept --redirect-call-sid --redirect-url --region --reservation-status --sip-auth-password --sip-auth-username --start-conference-on-enter --status-callback --status-callback-event --status-callback-method --supervisor --supervisor-mode --timeout --to --wait-method --wait-url --worker-activity-sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:tasks:reservations:fetch --workspace-sid --task-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:create --workspace-sid --activity-sid --attributes --friendly-name --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:list --workspace-sid --activity-name --activity-sid --available --friendly-name --target-workers-expression --task-queue-name --task-queue-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:cumulative-statistics:fetch --workspace-sid --end-date --minutes --start-date --task-channel --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:real-time-statistics:fetch --workspace-sid --task-channel --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:statistics:fetch --workspace-sid --minutes --start-date --end-date --task-queue-sid --task-queue-name --friendly-name --task-channel --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:update --workspace-sid --sid --activity-sid --attributes --friendly-name --reject-pending-reservations --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:fetch --workspace-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:remove --workspace-sid --sid --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:channels:list --workspace-sid --worker-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:channels:update --workspace-sid --worker-sid --sid --available --capacity --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:channels:fetch --workspace-sid --worker-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:reservations:list --workspace-sid --worker-sid --reservation-status --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:reservations:update --workspace-sid --worker-sid --sid --beep --beep-on-customer-entrance --call-accept --call-from --call-record --call-status-callback-url --call-timeout --call-to --call-url --conference-record --conference-recording-status-callback --conference-recording-status-callback-method --conference-status-callback --conference-status-callback-event --conference-status-callback-method --conference-trim --dequeue-from --dequeue-post-work-activity-sid --dequeue-record --dequeue-status-callback-event --dequeue-status-callback-url --dequeue-timeout --dequeue-to --early-media --end-conference-on-customer-exit --end-conference-on-exit --from --instruction --max-participants --muted --post-work-activity-sid --record --recording-channels --recording-status-callback --recording-status-callback-method --redirect-accept --redirect-call-sid --redirect-url --region --reservation-status --sip-auth-password --sip-auth-username --start-conference-on-enter --status-callback --status-callback-event --status-callback-method --timeout --to --wait-method --wait-url --worker-activity-sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:reservations:fetch --workspace-sid --worker-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workers:statistics:fetch --workspace-sid --worker-sid --minutes --start-date --end-date --task-channel --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workflows:create --workspace-sid --assignment-callback-url --configuration --fallback-assignment-callback-url --friendly-name --task-reservation-timeout --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workflows:list --workspace-sid --friendly-name --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workflows:update --workspace-sid --sid --assignment-callback-url --configuration --fallback-assignment-callback-url --friendly-name --re-evaluate-tasks --task-reservation-timeout --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workflows:fetch --workspace-sid --sid --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workflows:remove --workspace-sid --sid --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workflows:cumulative-statistics:fetch --workspace-sid --workflow-sid --end-date --minutes --start-date --task-channel --split-by-wait-time --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workflows:real-time-statistics:fetch --workspace-sid --workflow-sid --task-channel --properties --profile --cli-log-level --cli-output-format
api:taskrouter:v1:workspaces:workflows:statistics:fetch --workspace-sid --workflow-sid --minutes --start-date --end-date --task-channel --split-by-wait-time --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:create --cnam-lookup-enabled --disaster-recovery-method --disaster-recovery-url --domain-name --friendly-name --secure --transfer-mode --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:update --sid --cnam-lookup-enabled --disaster-recovery-method --disaster-recovery-url --domain-name --friendly-name --secure --transfer-mode --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:remove --sid --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:credential-lists:create --trunk-sid --credential-list-sid --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:credential-lists:list --trunk-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:credential-lists:fetch --trunk-sid --sid --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:credential-lists:remove --trunk-sid --sid --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:ip-access-control-lists:create --trunk-sid --ip-access-control-list-sid --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:ip-access-control-lists:list --trunk-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:ip-access-control-lists:fetch --trunk-sid --sid --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:ip-access-control-lists:remove --trunk-sid --sid --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:origination-urls:create --trunk-sid --enabled --friendly-name --priority --sip-url --weight --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:origination-urls:list --trunk-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:origination-urls:update --trunk-sid --sid --enabled --friendly-name --priority --sip-url --weight --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:origination-urls:fetch --trunk-sid --sid --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:origination-urls:remove --trunk-sid --sid --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:phone-numbers:create --trunk-sid --phone-number-sid --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:phone-numbers:list --trunk-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:phone-numbers:fetch --trunk-sid --sid --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:phone-numbers:remove --trunk-sid --sid --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:recording:update --trunk-sid --properties --profile --cli-log-level --cli-output-format
api:trunking:v1:trunks:recording:fetch --trunk-sid --properties --profile --cli-log-level --cli-output-format
api:verify:v2:forms:fetch --form-type --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:create --code-length --custom-code-enabled --do-not-share-warning-enabled --dtmf-input-required --friendly-name --lookup-enabled --psd2-enabled --push --skip-sms-to-landlines --tts-name --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:verify:v2:services:access-tokens:create --service-sid --factor-type --identity --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:create --service-sid --twilio-sandbox-mode --identity --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:list --service-sid --twilio-sandbox-mode --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:fetch --service-sid --identity --twilio-sandbox-mode --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:remove --service-sid --identity --twilio-sandbox-mode --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:challenges:create --service-sid --identity --twilio-sandbox-mode --details --expiration-date --factor-sid --hidden-details --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:challenges:list --service-sid --identity --twilio-sandbox-mode --factor-sid --status --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:challenges:update --service-sid --identity --sid --twilio-sandbox-mode --auth-payload --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:challenges:fetch --service-sid --identity --sid --twilio-sandbox-mode --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:factors:create --service-sid --identity --twilio-sandbox-mode --authorization --binding --config --factor-type --friendly-name --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:factors:list --service-sid --identity --twilio-sandbox-mode --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:factors:update --service-sid --identity --sid --twilio-sandbox-mode --auth-payload --config --friendly-name --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:factors:fetch --service-sid --identity --sid --twilio-sandbox-mode --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:entities:factors:remove --service-sid --identity --sid --twilio-sandbox-mode --profile --cli-log-level --cli-output-format
api:verify:v2:services:messaging-configurations:create --service-sid --country --messaging-service-sid --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:messaging-configurations:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:verify:v2:services:messaging-configurations:update --service-sid --country --messaging-service-sid --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:messaging-configurations:fetch --service-sid --country --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:messaging-configurations:remove --service-sid --country --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:create --service-sid --description --unique-name --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:buckets:create --service-sid --rate-limit-sid --interval --max --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:buckets:list --service-sid --rate-limit-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:buckets:update --service-sid --rate-limit-sid --sid --interval --max --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:buckets:fetch --service-sid --rate-limit-sid --sid --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:buckets:remove --service-sid --rate-limit-sid --sid --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:update --service-sid --sid --description --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:rate-limits:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:verify:v2:services:verification-check:create --service-sid --amount --code --payee --to --verification-sid --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:verifications:create --service-sid --amount --app-hash --channel --channel-configuration --custom-code --custom-friendly-name --custom-message --locale --payee --rate-limits --send-digits --to --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:verifications:update --service-sid --sid --status --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:verifications:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:webhooks:create --service-sid --event-types --friendly-name --status --webhook-url --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:webhooks:list --service-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:verify:v2:services:webhooks:update --service-sid --sid --event-types --friendly-name --status --webhook-url --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:webhooks:fetch --service-sid --sid --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:webhooks:remove --service-sid --sid --profile --cli-log-level --cli-output-format
api:verify:v2:services:update --sid --code-length --custom-code-enabled --do-not-share-warning-enabled --dtmf-input-required --friendly-name --lookup-enabled --psd2-enabled --push --skip-sms-to-landlines --tts-name --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:verify:v2:services:remove --sid --profile --cli-log-level --cli-output-format
api:video:v1:composition-hooks:create --audio-sources --audio-sources-excluded --enabled --format --friendly-name --resolution --status-callback --status-callback-method --trim --video-layout --properties --profile --cli-log-level --cli-output-format
api:video:v1:composition-hooks:list --enabled --date-created-after --date-created-before --friendly-name --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:video:v1:composition-hooks:update --sid --audio-sources --audio-sources-excluded --enabled --format --friendly-name --resolution --status-callback --status-callback-method --trim --video-layout --properties --profile --cli-log-level --cli-output-format
api:video:v1:composition-hooks:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:video:v1:composition-hooks:remove --sid --profile --cli-log-level --cli-output-format
api:video:v1:composition-settings:default:update --aws-credentials-sid --aws-s3-url --aws-storage-enabled --encryption-enabled --encryption-key-sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:video:v1:composition-settings:default:fetch --properties --profile --cli-log-level --cli-output-format
api:video:v1:compositions:create --audio-sources --audio-sources-excluded --format --resolution --room-sid --status-callback --status-callback-method --trim --video-layout --properties --profile --cli-log-level --cli-output-format
api:video:v1:compositions:list --status --date-created-after --date-created-before --room-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:video:v1:compositions:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:video:v1:compositions:remove --sid --profile --cli-log-level --cli-output-format
api:video:v1:recording-settings:default:update --aws-credentials-sid --aws-s3-url --aws-storage-enabled --encryption-enabled --encryption-key-sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:video:v1:recording-settings:default:fetch --properties --profile --cli-log-level --cli-output-format
api:video:v1:recordings:list --status --source-sid --grouping-sid --date-created-after --date-created-before --media-type --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:video:v1:recordings:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:video:v1:recordings:remove --sid --profile --cli-log-level --cli-output-format
api:video:v1:rooms:create --enable-turn --max-participants --media-region --record-participants-on-connect --status-callback --status-callback-method --type --unique-name --video-codecs --properties --profile --cli-log-level --cli-output-format
api:video:v1:rooms:list --status --unique-name --date-created-after --date-created-before --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:video:v1:rooms:participants:list --room-sid --status --identity --date-created-after --date-created-before --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:video:v1:rooms:participants:published-tracks:list --room-sid --participant-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:video:v1:rooms:participants:published-tracks:fetch --room-sid --participant-sid --sid --properties --profile --cli-log-level --cli-output-format
api:video:v1:rooms:participants:subscribe-rules:create --room-sid --participant-sid --rules --properties --profile --cli-log-level --cli-output-format
api:video:v1:rooms:participants:subscribe-rules:list --room-sid --participant-sid --properties --limit --profile --cli-log-level --cli-output-format
api:video:v1:rooms:participants:subscribed-tracks:list --room-sid --participant-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:video:v1:rooms:participants:subscribed-tracks:fetch --room-sid --participant-sid --sid --properties --profile --cli-log-level --cli-output-format
api:video:v1:rooms:participants:update --room-sid --sid --status --properties --profile --cli-log-level --cli-output-format
api:video:v1:rooms:participants:fetch --room-sid --sid --properties --profile --cli-log-level --cli-output-format
api:video:v1:rooms:recordings:list --room-sid --status --source-sid --date-created-after --date-created-before --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:video:v1:rooms:recordings:fetch --room-sid --sid --properties --profile --cli-log-level --cli-output-format
api:video:v1:rooms:recordings:remove --room-sid --sid --profile --cli-log-level --cli-output-format
api:video:v1:rooms:update --sid --status --properties --profile --cli-log-level --cli-output-format
api:video:v1:rooms:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:voice:v1:byoc-trunks:create --cnam-lookup-enabled --connection-policy-sid --friendly-name --from-domain-sid --status-callback-method --status-callback-url --voice-fallback-method --voice-fallback-url --voice-method --voice-url --properties --profile --cli-log-level --cli-output-format
api:voice:v1:byoc-trunks:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:voice:v1:byoc-trunks:update --sid --cnam-lookup-enabled --connection-policy-sid --friendly-name --from-domain-sid --status-callback-method --status-callback-url --voice-fallback-method --voice-fallback-url --voice-method --voice-url --properties --profile --cli-log-level --cli-output-format
api:voice:v1:byoc-trunks:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:voice:v1:byoc-trunks:remove --sid --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:create --friendly-name --properties --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:targets:create --connection-policy-sid --enabled --friendly-name --priority --target --weight --properties --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:targets:list --connection-policy-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:targets:update --connection-policy-sid --sid --enabled --friendly-name --priority --target --weight --properties --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:targets:fetch --connection-policy-sid --sid --properties --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:targets:remove --connection-policy-sid --sid --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:update --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:voice:v1:connection-policies:remove --sid --profile --cli-log-level --cli-output-format
api:voice:v1:dialing-permissions:bulk-country-updates:create --update-request --properties --profile --cli-log-level --cli-output-format
api:voice:v1:dialing-permissions:countries:list --iso-code --continent --country-code --low-risk-numbers-enabled --high-risk-special-numbers-enabled --high-risk-tollfraud-numbers-enabled --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:voice:v1:dialing-permissions:countries:fetch --iso-code --properties --profile --cli-log-level --cli-output-format
api:voice:v1:dialing-permissions:countries:high-risk-special-prefixes:list --iso-code --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:voice:v1:ip-records:create --cidr-prefix-length --friendly-name --ip-address --properties --profile --cli-log-level --cli-output-format
api:voice:v1:ip-records:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:voice:v1:ip-records:update --sid --friendly-name --properties --profile --cli-log-level --cli-output-format
api:voice:v1:ip-records:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:voice:v1:ip-records:remove --sid --profile --cli-log-level --cli-output-format
api:voice:v1:settings:update --dialing-permissions-inheritance --properties --profile --cli-log-level --cli-output-format
api:voice:v1:settings:fetch --properties --profile --cli-log-level --cli-output-format
api:voice:v1:source-ip-mappings:create --ip-record-sid --sip-domain-sid --properties --profile --cli-log-level --cli-output-format
api:voice:v1:source-ip-mappings:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:voice:v1:source-ip-mappings:update --sid --sip-domain-sid --properties --profile --cli-log-level --cli-output-format
api:voice:v1:source-ip-mappings:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:voice:v1:source-ip-mappings:remove --sid --profile --cli-log-level --cli-output-format
api:wireless:v1:commands:create --callback-method --callback-url --command --command-mode --delivery-receipt-requested --include-sid --sim --properties --profile --cli-log-level --cli-output-format
api:wireless:v1:commands:list --sim --status --direction --transport --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:wireless:v1:commands:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:wireless:v1:commands:remove --sid --profile --cli-log-level --cli-output-format
api:wireless:v1:rate-plans:create --data-enabled --data-limit --data-metering --friendly-name --international-roaming --international-roaming-data-limit --messaging-enabled --national-roaming-data-limit --national-roaming-enabled --unique-name --voice-enabled --properties --profile --cli-log-level --cli-output-format
api:wireless:v1:rate-plans:list --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:wireless:v1:rate-plans:update --sid --friendly-name --unique-name --properties --profile --cli-log-level --cli-output-format
api:wireless:v1:rate-plans:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:wireless:v1:rate-plans:remove --sid --profile --cli-log-level --cli-output-format
api:wireless:v1:sims:list --status --iccid --rate-plan --eid --sim-registration-code --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:wireless:v1:sims:update --sid --account-sid --callback-method --callback-url --commands-callback-method --commands-callback-url --friendly-name --rate-plan --reset-status --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status --unique-name --voice-fallback-method --voice-fallback-url --voice-method --voice-url --properties --profile --cli-log-level --cli-output-format
api:wireless:v1:sims:fetch --sid --properties --profile --cli-log-level --cli-output-format
api:wireless:v1:sims:remove --sid --profile --cli-log-level --cli-output-format
api:wireless:v1:sims:data-sessions:list --sim-sid --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:wireless:v1:sims:usage-records:list --sim-sid --end --start --granularity --page-size --properties --limit --profile --cli-log-level --cli-output-format
api:wireless:v1:usage-records:list --end --start --granularity --page-size --properties --limit --profile --cli-log-level --cli-output-format
phone-numbers:buy:local --account-sid --address-sid --api-version --area-code --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format --country-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --limit
phone-numbers:buy:machine-to-machine --account-sid --address-sid --api-version --area-code --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format --country-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --limit
phone-numbers:buy:mobile --account-sid --address-sid --api-version --area-code --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format --country-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --limit
phone-numbers:buy:national --account-sid --address-sid --api-version --area-code --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format --country-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --limit
phone-numbers:buy:shared-cost --account-sid --address-sid --api-version --area-code --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format --country-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --limit
phone-numbers:buy:toll-free --account-sid --address-sid --api-version --area-code --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format --country-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --limit
phone-numbers:buy:voip --account-sid --address-sid --api-version --area-code --bundle-sid --emergency-address-sid --emergency-status --friendly-name --identity-sid --sms-application-sid --sms-fallback-method --sms-fallback-url --sms-method --sms-url --status-callback --status-callback-method --trunk-sid --voice-application-sid --voice-caller-id-lookup --voice-fallback-method --voice-fallback-url --voice-method --voice-receive-mode --voice-url --properties --profile --cli-log-level --cli-output-format --country-code --contains --sms-enabled --mms-enabled --voice-enabled --exclude-all-address-required --exclude-local-address-required --exclude-foreign-address-required --beta --near-number --near-lat-long --distance --in-postal-code --in-region --in-rate-center --in-lata --in-locality --fax-enabled --page-size --limit
"

  if [[ "${COMP_CWORD}" -eq 1 ]] ; then
      opts=$(printf "$commands" | grep -Eo '^[a-zA-Z0-9:_-]+')
      COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
       __ltrim_colon_completions "$cur"
  else
      if [[ $cur == "-"* ]] ; then
        opts=$(printf "$commands" | grep "${COMP_WORDS[1]}" | sed -n "s/^${COMP_WORDS[1]} //p")
        COMPREPLY=( $(compgen -W  "${opts}" -- ${cur}) )
      fi
  fi
  return 0
}

complete -o default -F _twilio twilio
