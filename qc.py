
from subprocess import Popen, PIPE
import tempfile

# https://stackoverflow.com/questions/1158076/implement-touch-using-python#1160227
def touch(fname, times = None):
    with open(fname, 'a'):
        os.utime(fname, times)

if params['thresh']:
  print(params['thresh'])
  print(params['seed'])
else:
  print("No downsampling!")

for target in output:
  touch(target)

## fastp -i {input[0]} -I {input[1]} -o {output.pair1} -O {output.pair2} {params} -h {output.html} -j {output.json} -w {threads} > {log} 2>&1
