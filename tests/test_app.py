import unittest
from http.client import HTTPConnection
import subprocess
import time


class TestApplication(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.process = subprocess.Popen(["python3", "app.py"])
        time.sleep(2)

    @classmethod
    def tearDownClass(cls):
        cls.process.terminate()
        cls.process.wait()

    def test_health_check(self):
        connection = HTTPConnection("localhost", 8080)
        connection.request("GET", "/")
        response = connection.getresponse()

        self.assertEqual(response.status, 200)

        body = response.read().decode()
        self.assertIn("Health check feature", body)

        connection.close()


if __name__ == "__main__":
    unittest.main()
