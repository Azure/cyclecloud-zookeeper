# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

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


def _retry_call(cmd, attempts=3):
    for attempt in range(attempts):
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stdout, stderr = process.communicate()
        if process.returncode == 0:
            return stdout
        assert attempt < attempts - 1, "Command %s failed %d times.\nStdout: %s\nStderr:\n %s" %\
                                        (cmd, attempts, stdout, stderr)
            
        time.sleep(5 + 15 * attempt)

 
class TestZkServer(unittest.TestCase):
    
    def setUp(self):
        self.hostname = subprocess.check_output('hostname').strip()
        self.znode = '/zk_test_%s' % self.hostname
        self.server = '127.0.0.1'
    
    def tearDown(self):
        _retry_call(['/opt/zookeeper/current/bin/zkCli.sh', '-server', self.server,
                               'delete', self.znode])

    def test_create_znode(self):
        ready, stdout, stderr = zk_ready(self.server)
        self.assertTrue(ready,
                        msg="ZooKeeper server not ready after 5 minutes\nStdout: %s\nStderr: %s"
                        % (stdout, stderr))
        
        magic_string = 'superfoobar'
        _retry_call(['/opt/zookeeper/current/bin/zkCli.sh', '-server', self.server,
                               'create', self.znode, magic_string])
        
        get_stdout = _retry_call(['/opt/zookeeper/current/bin/zkCli.sh', '-server', self.server, 'get', self.znode])
        
        self.assertTrue(magic_string in get_stdout, msg="Expected value %s not found in output %s"
                        % (magic_string, get_stdout))
