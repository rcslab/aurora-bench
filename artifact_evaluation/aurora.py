import os
from pathlib import Path
import subprocess as sp

# This severely limits the amount of discrete functions we 
# can have active but it doesn't matter because the benchmarks
# don't populate the FS that heavily.
OID_MIN=1000
OID_MAX=(65535 - 1)

# Python versions of the Aurora management commands.

# For some reason passing sp.PIPE and sp.DEVNULL through 
# through output does not work.
def shell(cmd, pipe=False, mute=False, fail_okay=False):
    # Propagate the return code upwards
    stdout = None
    if pipe:
        stdout = sp.PIPE 
        stderr = sp.DEVNULL
    if mute:
        stdout = sp.DEVNULL
        stderr = sp.DEVNULL

    if stdout is not None:
        p = sp.run(cmd, stdout=stdout, stderr=stderr)
    else:
        p = sp.run(cmd)

    if not fail_okay:
        p.check_returncode()
    if p.stdout:
        return p.stdout.decode().rstrip(" \n")

def gstripe_command(command, *args):
    shell(["gstripe", command, *args], fail_okay=True)
    

def loadsls():
    sls_module = Path(os.environ["SRCROOT"], "sls", "sls.ko")
    shell(["kldload", sls_module])


def loadslos():
    slos_module = Path(os.environ["SRCROOT"], "slos", "slos.ko")
    shell(["kldload", slos_module])


def unloadsls():
    shell(["kldunload", "sls"], fail_okay=True)


def unloadslos():
    shell(["kldunload", "slos"], fail_okay=True)


def createmd(backing_file=None):
    if backing_file is not None:
        target = ["-t", "vnode", "-f", backing_file]
    else:
        target = ["-t", "malloc", "-s", "20g"]

    # We have to grab the output so we use run() directly.
    cmd = sp.Popen(["mdconfig", "-a"] + target, stdout=sp.PIPE)
    cmd.wait()
    disk = cmd.stdout.read().decode().rstrip()

    return (disk, Path("/dev/", disk))


def destroymd(disk):
    shell(["mdconfig", "-d", "-u", disk])


def slsnewfs(diskpath):
    newfs = Path(os.environ["SRCROOT"], "tools", "newfs_sls", "newfs_sls")
    # The newfs call emits useless diagnostics on stderr
    shell([newfs, diskpath], mute=True)


def slsmount(diskpath, mountpoint=None):
    # We cannot access os.environ as a standard argument afaict.
    if mountpoint == None:
        mountpoint = os.environ["MNT"]

    slsfs = Path(mountpoint)
    slsfs.mkdir(parents=True, exist_ok=True)
    shell(["mount", "-t", "slsfs", diskpath, slsfs])

    devfs = slsfs / "dev"
    devfs.mkdir(parents=True, exist_ok=True)
    shell(["mount", "-t", "devfs", "devfs", devfs])

    fdescfs = devfs / "fd"
    fdescfs.mkdir(parents=True, exist_ok=True)
    shell(["mount", "-t", "fdescfs", "fdescfs", fdescfs])

    procfs = slsfs / "proc"
    procfs.mkdir(parents=True, exist_ok=True)
    shell(["mount", "-t", "procfs", "procfs", procfs])


def slsunmount():
    shell(["umount", Path(os.environ["MNT"], "dev", "fd")])
    shell(["umount", Path(os.environ["MNT"], "dev")])
    shell(["umount", Path(os.environ["MNT"], "proc")])
    shell(["umount", Path(os.environ["MNT"])])


def aursetup(diskpath, create_newfs=True):
    loadslos()
    if create_newfs:
        slsnewfs(diskpath)
    slsmount(diskpath)
    loadsls()
    shell(["kldload", "hwpmc"], fail_okay=True, mute=True)

def aurteardown():
    unloadsls()
    slsunmount()
    unloadslos()

def partadd(oid, backend="slos", period=0, flag=""):
    slsctl = Path(os.environ["SRCROOT"], "tools", "slsctl", "slsctl")
    cmd = [slsctl, "partadd", backend, "-o", str(oid), "-d"]
    if flag:
        cmd.append(flag)
    shell(cmd)

def partdel(oid):
    slsctl = Path(os.environ["SRCROOT"], "tools", "slsctl", "slsctl")
    shell([slsctl, "partdel", "-o", str(oid)])

def burn_image(image, disk, bs="1m"):
    gstripe_command("load")
    shell(["dd", "if={}".format(image), "of={}".format(disk), "bs={}".format(bs)])

def sysctl_set(argument, value):
    shell(["sysctl", "{}={}".format(argument, value)])

def sysctl_config():
    sysctl_set("net.inet.tcp.fastopen.server_enable", "1")
    sysctl_set("net.inet.tcp.fastopen.client_enable", "1")

def installroot(mount, root):
    shell(["tar", "-C", mount, "-xf", root])

def sysctl(argument):
    return shell(["sysctl", "-n", argument], pipe=True) 

def sls_sysctl(argument):
    return sysctl("aurora.{}".format(argument))

def slos_sysctl(argument):
    return sysctl("aurora_slos.{}".format(argument))

def sls_sysctl_set(argument, value):
    return sysctl_set("aurora.{}".format(argument), value)

def slos_sysctl_set(argument, value):
    return sysctl_set("aurora_slos.{}".format(argument), value)

