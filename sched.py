from apscheduler.schedulers.background import BlockingScheduler
from datetime import datetime

def push():
    import os
    os.system('docker push 414140062450.dkr.ecr.us-east-1.amazonaws.com/ubuntu-python3-opencv:latest')

if __name__ == '__main__':
    scheduler = BlockingScheduler()

    scheduler.add_job(push, 'date', run_date=datetime(2017, 1, 10, 22, 30, 00))

    try:
        scheduler.start()
    except (KeyboardInterrupt, SystemExit):
        pass
