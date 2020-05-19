sudo docker build .

# convert to singularity image:
# 1119  sudo docker image list # to get the image ID
# 1113  sudo docker tag d77117cb2db8 saige/v1
# 1114  sudo docker image list
# 1117  sudo singularity build saige.img docker-daemon://saige/v1:latest
# 1127  sudo singularity build saige.img docker-daemon://saige/v1:latest
