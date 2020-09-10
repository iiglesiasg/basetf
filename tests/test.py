from shutil import copyfile
from sys import exit
import json
import os

lastenvs = []
src = 'templates/test'


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


print(rec_func('../iac/environments'))


def copy_test(src,dst,rpl):
    f = open(src, "r")
    testcontent = f.read()
    testcontent = testcontent.replace('CHANGEME', rpl)
    f.close()
    f = open(dst, "w")
    f.write(testcontent)
    f.close()

with open('test.json', 'r') as file:
    tests_data = json.load(file)
    for test in tests_data:
        denormalized_folder = test['folder']
        file_name = test['file']
        content = test['content']
        normalized_folder = "environments/" + denormalized_folder.replace("_", "/") + '/'
        print(normalized_folder)
        dst = '../iac/'+normalized_folder + file_name
        copy_test(src+'.tfvars', dst+'.tfvars', content)
        copy_test(src+'.tf', dst+'.tf', content)
    file.close()

