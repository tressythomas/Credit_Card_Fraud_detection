
#Credit Card Fraud Detection
# Anomaly detection of fraud CC transaction.
# Dataset is sourced from Kaggle. The data is highly imbalanced as is the case of most anomaly detection cases. 
# In order to handle the imbalance in data 3 different methods are utilised. SMOTE, MWMORE and Undersampling. 
# As accuracy is not the appropriate metric for model measurement, Balanced accuracy as well specificity and prediction are also taken into account. 
# 
# 
# 
# I have used 3 classifiers, Logistic Regression, SVC and XGBoost to predict if the transaction is fraud or not.
# 
# XGBoost  with SMOTE data resulted in 
# Balanced Accuracy : 0.93094 
# Sensitivity : 0.98432            
# Specificity : 0.87755            
# Pos Pred Value : 0.99979
# which is the best observed test model performance.
library(gbm)
library(ggplot2)
library(caret)
library(dplyr)
library(reshape2)
options(scipen=999)
#Read the file
data=read.csv("C:\\Users\\Tress\\OneDrive\\Desktop\\Learn\\Dataset\\creditcard.csv")
summary(data)
data$Class=factor(data$Class)
min(data$Amount)
max(data$Amount)
hist(data$Amount)

###################################################################################
#Visuals
###################################################################################
# Distribution of classes 
table(data$Class)

dist_plot=ggplot(data=data,aes(x=Class),stat="identity")+
  geom_bar(aes(color=factor(Class)))
dist_plot

#Distribution of amount
dist_plot_Amt=ggplot(data=data[data$Class=='1',],aes(x=Amount),stat="identity")+
  geom_bar(aes(color=Class))
dist_plot_Amt

#Time vs Clas
dist_plot_Time=ggplot(data=data,aes(x=Time),stat="identity")+
  geom_bar(aes(color=Class))
dist_plot_Time


temp=data%>%
  group_by(round(Amount),Class)%>%
  summarise(cnt=n())
dist_plot_grpAmt=ggplot(data=temp,aes(x=`round(Amount)`,y=cnt))+
  geom_point(aes(color=Class))
dist_plot_grpAmt

# AMOUNT VS TIME RELATIONSHIP 
scatter_plot=ggplot(data=data,aes(y=Amount,x=Time))+
                      geom_point(aes(color=factor(Class)))
scatter_plot
###################################################################################
# cORRELATION 
heatmap=qplot(x = Var1, y = Var2,
              data = melt(cor(data, use = "p")),
              fill = value,
              geom = "tile") +
  scale_fill_gradient2(limits = c(-1, 1))

heatmap

#Boxplot 
box_plot=ggplot(data=data,aes(x=Class, y=Amount))+
  geom_boxplot(outlier.colour="red", outlier.shape=8,
               outlier.size=4)

box_plot
###################################################################################
#Split data 70:30
set.seed(101)
train.ix=createDataPartition(data$Class,p=0.7, list = F)
train_data=data[train.ix,]
test_data=data[-train.ix,]
table(train_data$Class)
table(test_data$Class)
###################################################################################
#Imbalanaced data problem - Under-representation of a class 
######### Handling Imbalanced Data #########

#SMOTE - Synthetic Minority Over-sampling Technique 
library(DMwR)
SMOTE_ds=SMOTE(Class~.,train_data,perc.over = 600, k=5, perc.under = 100)
table(SMOTE_ds$Class)
#MWMOTE Majority Weighted Minority Oversampling TEchnique 
library(imbalance)
MWMOTE_ds=rbind(train_data,mwmote(train_data, numInstances = 50000))
table(MWMOTE_ds$Class)
#UNDERSAMPLING Random
down_ds=downSample(x=train_data[,1:30],
                   y=train_data[,31])
table(down_ds$Class)
#OVERSAMPLING - RApidly COnverging Gibbs
# over_ds=rbind(train_data,racog(train_data,numInstances = 20000))
# table(over_ds$Class)


#FEATURE SELECTION- RFE 
###################################################################################
RFE_Features= rfe(SMOTE_ds[,1:30], SMOTE_ds[,31], 
                  sizes=c(1:30), 
                  rfeControl = rfeControl(functions=rfFuncs,method="cv", number=5))
print(RFE_Features)
plot(RFE_Features, type = c("o", "g"))
###################################################################################  
RFE_Features_MWMOTE= rfe(MWMOTE_ds[,1:30], MWMOTE_ds[,31], 
                  sizes=c(1:30), 
                  rfeControl = rfeControl(functions=rfFuncs,method="cv", number=5))

print(RFE_Features_MWMOTE)
plot(RFE_Features_MWMOTE, type = c("o", "g"))
###################################################################################
RFE_Features_down= rfe(down_ds[,1:30], down_ds[,31], 
                         sizes=c(1:30), 
                         rfeControl = rfeControl(functions=rfFuncs,method="cv", number=5))

print(RFE_Features_down)
plot(RFE_Features_down, type = c("o", "g"))
###################################################################################
RFE_Features_over= rfe(over_ds[,1:30], over_ds[,31], 
                       sizes=c(1:30), 
                       rfeControl = rfeControl(functions=rfFuncs,method="cv", number=5))

print(RFE_Features_over)
plot(RFE_Features_over, type = c("o", "g"))
###################################################################################
# create formula
attr=predictors(RFE_Features)[1:15]
# attr=predictors(RFE_Features_MWMOTE)[1:15]
# attr=predictors(RFE_Features_down)[1:15]
# attr=predictors(RFE_Features_over)[1:15]
a=paste(sprintf("`%s`",attr), collapse= "+");b=paste("Class ~ ", a)
fmla=as.formula(b)

levels(SMOTE_ds$Class)=c('Normal','Fraud')
levels(test_data$Class)=c('Normal','Fraud')
###################################################################################
##########MODELLING Using SMOTE Data ##########

#1. Logistic 
logit.model=train(fmla,
                  data=SMOTE_ds[,c(attr,'Class')],
                  # preProcess = c("center","scale"),
                  trControl = trainControl(method="cv", number=5,
                                           summaryFunction=twoClassSummary, classProbs=T,
                                           savePredictions = T),
                  method = "glm",family="binomial",
                  trace=FALSE)
#2. SVM
svm.model=train(fmla,
                   data=SMOTE_ds[,c(attr,'Class')],
                   # preProcess = c("center","scale"),
                   trControl = trainControl(method="cv", number=5,
                                            summaryFunction=twoClassSummary, classProbs=T,
                                            savePredictions = T),
                   method = "svmRadial",
                   trace=FALSE)

#3. XGBOOST
library(xgboost)
SMOTE_ds$Class=ifelse(SMOTE_ds$Class=='Normal',0,1)

trn=as.matrix(SMOTE_ds[,c(attr)])
Cls=as.matrix(SMOTE_ds$Class)

xgb.model <- xgboost(
  data = trn,
  label = Cls,
  nrounds = 1500,
  objective ="binary:logistic",
  #nfold = 5,
  early_stopping_rounds = 20,
  verbose = 0               # evaluation metric out,
)

#4. Neural Network
library(neuralnet)
SMOTE_ds$Class=ifelse(SMOTE_ds$Class=='Normal',0,1)
train_data_matrix=as.matrix(SMOTE_ds[,c(attr,'Class')])

maxs <- apply(train_data_matrix, 2, max) 
mins <- apply(train_data_matrix, 2, min)
scaled_SMOTE_ds <- as.data.frame(scale(train_data_matrix, center = mins, scale = maxs - mins))
# train_data=scaled[train_ix,]
# test_data=scaled[-train_ix,]
nn.model <- neuralnet(fmla,data=scaled_SMOTE_ds,hidden=32,linear.output=F,stepmax = 100000,threshold = .005)
###################################################################################

######### Testing SMOTE Data ############
predClass.logit=predict(logit.model,test_data[,c(attr)])
logit.cm=confusionMatrix(predClass.logit,test_data$Class)

predClass.svm=predict(svm.model,test_data[,c(attr)])
svm.cm=confusionMatrix(predClass.svm,test_data$Class)


test_data$Class=as.matrix(ifelse(test_data$Class=='Normal',0,1))
prob_predClass.gbm=predict(xgb.model,as.matrix(test_data[,c(attr)]))
predClass.gbm <- ifelse(prob_predClass.gbm > 0.5, 1, 0)
gbm.cm=confusionMatrix(as.factor(predClass.gbm),factor(test_data$Class))

logit.cm$overall[1];svm.cm$overall[1];gbm.cm$overall[1]
logit.cm$byClass[11];svm.cm$byClass[11];gbm.cm$byClass[11]

test_data$Class=as.matrix(ifelse(test_data$Class=='Normal',0,1))
maxs <- apply(test_data, 2, max) 
mins <- apply(test_data, 2, min)
scaled_test_data <- as.data.frame(scale(test_data, center = mins, scale = maxs - mins))
scaled_test_data=as.matrix(scaled_test_data[,c(attr)])
prob_predClass.nn=predict(nn.model,scaled_test_data)
predClass.nn <- ifelse(prob_predClass.nn > 0.5, 1, 0)
nn.cm=confusionMatrix(as.factor(predClass.nn),factor(test_data$Class))

##########MODELLING Using MWMOTE Data ##########
levels(MWMOTE_ds$Class)=c('Normal','Fraud')
levels(test_data$Class)=c('Normal','Fraud')
#1. Logistic 
logit.model=train(fmla,
                  data=MWMOTE_ds[,c(attr,'Class')],
                  # preProcess = c("center","scale"),
                  trControl = trainControl(method="cv", number=5,
                                           summaryFunction=twoClassSummary, classProbs=T,
                                           savePredictions = T),
                  method = "glm",family="binomial",
                  trace=FALSE)
#2. SVM
svm.model=train(fmla,
                data=MWMOTE_ds[,c(attr,'Class')],
                # preProcess = c("center","scale"),
                trControl = trainControl(method="cv", number=5,
                                         summaryFunction=twoClassSummary, classProbs=T,
                                         savePredictions = T),
                method = "svmRadial",
                trace=FALSE)

#3. XGBOOST
library(xgboost)
MWMOTE_ds$Class=ifelse(MWMOTE_ds$Class=='Normal',0,1)

trn=as.matrix(MWMOTE_ds[,c(attr)])
Cls=as.matrix(MWMOTE_ds$Class)

xgb.model <- xgboost(
  data = trn,
  label = Cls,
  nrounds = 1500,
  objective ="binary:logistic",
  #nfold = 5,
  early_stopping_rounds = 20,
  verbose = 0               # evaluation metric out,
)

#4. Neural Network
library(neuralnet)
#MWMOTE_ds$Class=ifelse(MWMOTE_ds$Class=='Normal',0,1)
train_data_matrix=as.matrix(MWMOTE_ds[,c(attr,'Class')])

maxs <- apply(train_data_matrix, 2, max) 
mins <- apply(train_data_matrix, 2, min)
scaled_MWMOTE_ds <- as.data.frame(scale(train_data_matrix, center = mins, scale = maxs - mins))
# train_data=scaled[train_ix,]
# test_data=scaled[-train_ix,]
nn.model <- neuralnet(fmla,data=scaled_SMOTE_ds,hidden=32,linear.output=F,stepmax = 100000,threshold = .005)

######### Testing MWMOTE Data MODELS############
predClass.logit=predict(logit.model,test_data[,c(attr)])
MWMOTElogit.cm=confusionMatrix(predClass.logit,test_data$Class)

predClass.svm=predict(svm.model,test_data[,c(attr)])
MWMOTEsvm.cm=confusionMatrix(factor(predClass.svm),test_data$Class)


test_data$Class=as.matrix(ifelse(test_data$Class=='Normal',0,1))
prob_predClass.gbm=predict(xgb.model,as.matrix(test_data[,c(attr)]))
predClass.gbm <- ifelse(prob_predClass.gbm > 0.5, 1, 0)
MWMOTEgbm.cm=confusionMatrix(as.factor(predClass.gbm),factor(test_data$Class))

logit.cm$overall[1];svm.cm$overall[1];gbm.cm$overall[1]
logit.cm$byClass[11];svm.cm$byClass[11];gbm.cm$byClass[11]

MWMOTElogit.cm$overall[1];MWMOTEsvm.cm$overall[1];MWMOTEgbm.cm$overall[1]
MWMOTElogit.cm$byClass[11];MWMOTEsvm.cm$byClass[11];MWMOTEgbm.cm$byClass[11]

test_data$Class=as.matrix(ifelse(test_data$Class=='Normal',0,1))
maxs <- apply(test_data, 2, max) 
mins <- apply(test_data, 2, min)
scaled_test_data <- as.data.frame(scale(test_data, center = mins, scale = maxs - mins))
scaled_test_data=as.matrix(scaled_test_data[,c(attr)])
prob_predClass.nn=predict(nn.model,scaled_test_data)
predClass.nn <- ifelse(prob_predClass.nn > 0.5, 1, 0)
MWMOTEnn.cm=confusionMatrix(as.factor(predClass.nn),factor(test_data$Class))

##########MODELLING Using downsampled data##########
levels(down_ds$Class)=c('Normal','Fraud')
levels(test_data$Class)=c('Normal','Fraud')
#1. Logistic 
logit.model=train(fmla,
                  data=down_ds[,c(attr,'Class')],
                  # preProcess = c("center","scale"),
                  trControl = trainControl(method="cv", number=5,
                                           summaryFunction=twoClassSummary, classProbs=T,
                                           savePredictions = T),
                  method = "glm",family="binomial",
                  trace=FALSE)
#2. SVM
svm.model=train(fmla,
                data=down_ds[,c(attr,'Class')],
                # preProcess = c("center","scale"),
                trControl = trainControl(method="cv", number=5,
                                         summaryFunction=twoClassSummary, classProbs=T,
                                         savePredictions = T),
                method = "svmRadial",
                trace=FALSE)

#3. XGBOOST
library(xgboost)
down_ds$Class=ifelse(down_ds$Class=='Normal',0,1)

trn=as.matrix(down_ds[,c(attr)])
Cls=as.matrix(down_ds$Class)

xgb.model <- xgboost(
  data = trn,
  label = Cls,
  nrounds = 1500,
  objective ="binary:logistic",
  #nfold = 5,
  early_stopping_rounds = 20,
  verbose = 0               # evaluation metric out,
)


######### Testing MWMOTE Data MODELS############
predClass.logit=predict(logit.model,test_data[,c(attr)])
dslogit.cm=confusionMatrix(predClass.logit,test_data$Class)

predClass.svm=predict(svm.model,test_data[,c(attr)])
dssvm.cm=confusionMatrix(factor(predClass.svm),test_data$Class)


test_data$Class=as.matrix(ifelse(test_data$Class=='Normal',0,1))
prob_predClass.gbm=predict(xgb.model,as.matrix(test_data[,c(attr)]))
predClass.gbm <- ifelse(prob_predClass.gbm > 0.5, 1, 0)
dsgbm.cm=confusionMatrix(as.factor(predClass.gbm),factor(test_data$Class))

logit.cm$overall[1];svm.cm$overall[1];gbm.cm$overall[1]
logit.cm$byClass[11];svm.cm$byClass[11];gbm.cm$byClass[11]

MWMOTElogit.cm$overall[1];MWMOTEsvm.cm$overall[1];MWMOTEgbm.cm$overall[1]
MWMOTElogit.cm$byClass[11];MWMOTEsvm.cm$byClass[11];MWMOTEgbm.cm$byClass[11]

dslogit.cm$overall[1];dssvm.cm$overall[1];dsgbm.cm$overall[1]
dslogit.cm$byClass[11];MWMOTEsvm.cm$byClass[11];MWMOTEgbm.cm$byClass[11]

# XGBoost  with SMOTE data resulted in 
# Balanced Accuracy : 0.93094 
# Sensitivity : 0.98432            
# Specificity : 0.87755            
# Pos Pred Value : 0.99979
# which is the best observed test model performance.

