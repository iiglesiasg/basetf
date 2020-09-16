import json
import os
import sys


working_folder = sys.argv[1]
working_env = '../iac/' + working_folder + sys.argv[2]

lastenvs = []
validation_values = []

def rec_func(dirname: str):
    subfolders = [f.path for f in os.scandir(dirname) if f.is_dir()]
    if not list(subfolders):
        return dirname;
    else:
        for dirname in list(subfolders):
            env = rec_func(dirname)
            if isinstance(env,str):
                lastenvs.append(env)
        return lastenvs


print(rec_func('../iac/' + working_folder + '/environments'))

with open('test.json', 'r') as file:

    tests_data = json.load(file)

    for test in tests_data:

        denormalized_folder = test['folder']
        file_name = test['file']
        content = test['content']

        normalized_folder = '../iac/' + working_folder + '/environments/' + denormalized_folder.replace("_", "/") + '/'
        print(normalized_folder)

        lastenvs = rec_func('../iac/' + working_folder + normalized_folder)
        if working_env in lastenvs:
            f = open(normalized_folder + file_name + '.tfvars', 'r')
            file_content = f.read()
            f.close()
            if content in file_content:
                validation_values.append(content)

    print(f"::set-output name=validation_values::{validation_values}")

    file.close()

