EzAuth.TestRepo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(EzAuth.TestRepo, :manual)

EzAuth.Test.Endpoint.start_link()

Mimic.copy(EzAuth.Accounts)
Mimic.copy(EzAuth.Auth)
Mimic.copy(EzAuth.Config)
Mimic.copy(EzAuth.Test.Endpoint)
Mimic.copy(EzAuth.Test.Sender)
Mimic.copy(EzAuth.Test.Handler)
Mimic.copy(EzAuth.Test.Strategy)

ExUnit.start()
