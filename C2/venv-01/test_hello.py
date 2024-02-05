from hello import hello
from click.testing import CliRunner

def test_hello():
   runner = CliRunner()
   result = runner.invoke(hello, ["--name", "Thor","--color", "green"])
   assert "Thor" in result.output
  