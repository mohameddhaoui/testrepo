import click


@click.group(invoke_without_command=True)
@click.option(
    "-s",
    "--source",
    required=True,
    help="Data source name.",
)
@click.pass_context
def cli(source: str):
    """
    Root command.
    """
    print(source)
