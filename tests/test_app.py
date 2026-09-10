import unittest
import os
from http.client import HTTPConnection
import subprocess
import time


class TestApplication(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.process = subprocess.Popen(["python3", "app.py"], env={**os.environ, "PORT": "8090"})
        time.sleep(2)

    @classmethod
    def tearDownClass(cls):
        cls.process.terminate()
        cls.process.wait()

    def test_health_check(self):
        connection = HTTPConnection("localhost", 8090)
        connection.request("GET", "/")
        response = connection.getresponse()

        self.assertEqual(response.status, 200)

        body = response.read().decode()
        self.assertIn("Health check feature", body)

        connection.close()


if __name__ == "__main__":
    unittest.main()
