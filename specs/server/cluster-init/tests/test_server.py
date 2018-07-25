import unittest
import subprocess
import time


def _zk_get_root(ip):
    p = subprocess.Popen(['/opt/zookeeper/current/bin/zkCli.sh', '-server', ip,
                          'get', '/'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = p.communicate()
    return (p, stdout, stderr)

    
def zk_ready(ip):
    '''Calls zkCli.sh get / until it responds w/out a failure'''
    timeout = (60 * 5)

    # 5 minutes from now
    deadline = timeout + time.time()
    while time.time() < deadline:
        p, stdout, stderr = _zk_get_root(ip)
        success = p.returncode == 0
        if success:
            break

    return success, stdout, stderr

 
class TestZkServer(unittest.TestCase):
    
    def setUp(self):
        self.hostname = subprocess.check_output('hostname').strip()
        self.znode = '/zk_test_%s' % self.hostname
        self.server = '127.0.0.1'
    
    def tearDown(self):
        subprocess.check_call(['/opt/zookeeper/current/bin/zkCli.sh', '-server', self.server,
                               'delete', self.znode])

    def test_create_znode(self):
        ready, stdout, stderr = zk_ready(self.server)
        self.assertTrue(ready,
                        msg="ZooKeeper server not ready after 5 minutes\nStdout: %s\nStderr: %s"
                        % (stdout, stderr))
        
        magic_string = 'superfoobar'
        subprocess.check_call(['/opt/zookeeper/current/bin/zkCli.sh', '-server', self.server,
                               'create', self.znode, magic_string])
        
        p = subprocess.Popen(['/opt/zookeeper/current/bin/zkCli.sh', '-server', self.server, 'get',
                              self.znode], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        
        stdout, stderr = p.communicate()
        self.assertEqual(0, p.returncode,
                         msg="Create of znode %s failed with stdout: %s\nstderr:%s" % (self.znode, stdout, stderr))
        
        self.assertTrue(magic_string in stdout, msg="Expected value %s not found in output %s"
                        % (magic_string, stdout))
