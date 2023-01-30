#!/usr/bin/python
import sys
import yaml


data = {"scrape_configs": [{"job_name": "locust", "scrape_interval": "2s",
                            "static_configs": [{"targets": [sys.argv[1]]}]}]}

with open('prometheus.yml', 'w') as outfile:
    yaml.dump(data, outfile, default_flow_style=False)
