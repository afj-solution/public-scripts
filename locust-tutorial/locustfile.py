from locust import HttpUser, task, between

class QuickstartUser(HttpUser):
    wait_time = between(1, 2)
    
    token = ""

    def on_start(self):
       resp = self.client.post("/login", json={"username":"blackjneco", "password":"Test123$"})
       json_response_dict = resp.json()
       self.token = json_response_dict['token']

    @task
    def hello_world(self):
        self.client.headers['Content-Type'] = "application/json"
        self.client.headers['Authorization'] = "Bearer" + self.token
        self.client.get("/category", )
