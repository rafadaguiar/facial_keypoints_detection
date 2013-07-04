# Load Phase
data.dir = "/Users/rafadaguiar/Documents/Workspace/Kaggle/facial_keypoints_detection/data/"
train.file <-paste0(data.dir,"training.csv")
test.file <-paste0(data.dir,'test.csv')
d.train <-read.csv(train.file,stringsAsFactors=F)
im.train <- d.train$Image
d.train$Image <- NULL

install.packages('doMC') # parallel computation library to help on image munge
library(doMC)
registerDoMC()

# Munge Phase
im.train <- foreach(im = im.train, .combine=rbind) %dopar% {
  as.integer(unlist(strsplit(im, " ")))
}

d.test  <- read.csv(test.file, stringsAsFactors=F)
im.test <- foreach(im = d.test$Image, .combine=rbind) %dopar% {
  as.integer(unlist(strsplit(im, " ")))
}
d.test$Image <- NULL

save(d.train, im.train, d.test, im.test, file=paste0(data.dir,'data.Rd')) #save dataframes to avoid need of running the processing again

# Prediction Phase
# Naive prediction by feature means
p <- matrix(data=colMeans(d.train,na.rm=T),nrow=nrow(d.test),ncol=ncol(d.train),byrow=T)
colnames(p) <- names(d.train)
predictions <- data.frame(ImageId=1:nrow(d.test),p)

install.packages("reshape2")
library(reshape2)
submission <-melt(predictions, id.vars="ImageId",variable.name="FeatureName",value.name="Location") #Submission formating

example.submission <-read.csv(paste0(data.dir,'SampleSubmission.csv'))
sub.col.names <- names(example.submission)
example.submission$Location <- NULL
submission <- merge(example.submission,submission,all.x=T,sort=F)
submission <-submission[,sub.col.names]
write.csv(submission,file=paste0(data.dir,"submission_means.csv"),quote=F,row.names=F)