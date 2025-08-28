ExUnit.start()

# Start the XpandoNode application for testing
{:ok, _} = Application.ensure_all_started(:xpando_node)
