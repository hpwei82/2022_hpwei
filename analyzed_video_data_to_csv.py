from argparse import ArgumentParser

from per_analysis.io import read_data

parser = ArgumentParser()
parser.add_argument("--input", type=str, help="input directory", required=True)
parser.add_argument(
    "--info-file",
    type=str,
    help="path to csv file containing odor sequence for each fly",
)
parser.add_argument("--output", type=str, help="output file", required=True)
parser.add_argument(
    "--recursive", action="store_true", help="look for files in subdirectories"
)
parser.add_argument(
    "-v",
    "--verbosity",
    action="count",
    help="increase output verbosity",
    default=0,
)

args = parser.parse_args()

df = read_data(
    args.input,
    recursive=args.recursive,
    info_file=args.info_file,
    verbosity=args.verbosity,
)

if args.output.lower().endswith(".csv"):
    from pathlib import Path

    Path(args.output).parent.mkdir(exist_ok=True, parents=True)
    df.to_csv(args.output)
else:
    raise NotImplementedError
