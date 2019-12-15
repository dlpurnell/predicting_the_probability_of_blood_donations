#data preparation
library(forecast)
library(car)
library(MASS)
library(TTR)
library(MVN)
library(boot)
library(ResourceSelection) 
library(leaps)
library(pROC)
#read data
mydata=read.csv(file.choose(), header=TRUE, na.strings=c(""))
head(mydata)
summary(mydata)
# Exploratory Data Analysis
# Check for NAs and Missing Values
sapply(mydata,function(x) sum(is.na(x)))
sapply(mydata, function(x) length(unique(x)))
# Subset the data to what will be modified for regression
# we don't need the index or predictor variable for regression
blooddata <- subset(mydata, select= c(2,3,4,5))
# Plot variables
attach(blooddata)
hist(Months.since.Last.Donation)
boxplot(Months.since.Last.Donation, main="Boxplot of Months since Last Donation")
ftable(Months.since.Last.Donation)
hist(Number.of.Donations)
boxplot(Number.of.Donations, main="Boxplot of Number of Donations")
ftable(Number.of.Donations)
hist(Total.Volume.Donated..c.c..)
boxplot(Total.Volume.Donated..c.c.., main="Boxplot of Total Volume of Donations")
ftable(Total.Volume.Donated..c.c..)
hist(Months.since.First.Donation)
boxplot(Months.since.First.Donation, main="Boxplot of Months since First Donation")
ftable(Months.since.First.Donation)
hist(mydata$Made.Donation.in.March.2007) #response variable
ftable(mydata$Made.Donation.in.March.2007)
# View inital relationships
kdepairs(mydata[,2:6])
# Transformations
xfer = blooddata + 1
myt=powerTransform(as.matrix(xfer)~1)
myt$lambda
testTransform(myt,myt$lambda)
xfer$Months.since.Last.Donation = xfer$Months.since.Last.Donation^myt$lambda[1]
xfer$Number.of.Donations = xfer$Number.of.Donations^myt$lambda[2]
xfer$Total.Volume.Donated..c.c.. = xfer$Total.Volume.Donated..c.c..^myt$lambda[3]
xfer$Months.since.First.Donation = xfer$Months.since.First.Donation^myt$lambda[4]
finalxfer = data.frame(mydata$X, xfer$Months.since.Last.Donation, xfer$Number.of.Donations,
             xfer$Total.Volume.Donated..c.c.., xfer$Months.since.First.Donation, 
             mydata$Made.Donation.in.March.2007)
kdepairs(finalxfer[,2:6])
# Split into training and test data
train <- finalxfer[1:384,]
test <- finalxfer[385:576,]
# Model Creation
#Baseline data
basetrain <- mydata[1:384,]
basetest <- mydata[385:576,]
#Baseline linear regression 
fit1 <- lm(Made.Donation.in.March.2007 ~ Months.since.Last.Donation + Number.of.Donations +
             Total.Volume.Donated..c.c.. + Months.since.First.Donation, data=basetrain)
#Baseline logistic regression
fit2 <- glm(Made.Donation.in.March.2007 ~ Months.since.Last.Donation + Number.of.Donations +
              Total.Volume.Donated..c.c.. + Months.since.First.Donation, data=basetrain,
              family = binomial(link="logit"))
# Box Cox Transformation with Linear Regression
fit3 <- lm(mydata.Made.Donation.in.March.2007 ~ xfer.Months.since.Last.Donation + 
             xfer.Number.of.Donations + xfer.Total.Volume.Donated..c.c.. + 
             xfer.Months.since.First.Donation, data=train)
# Box Cox Transform with Logistic Regression
fit4 <- glm(mydata.Made.Donation.in.March.2007 ~ xfer.Months.since.Last.Donation + 
                     xfer.Number.of.Donations + xfer.Total.Volume.Donated..c.c.. + 
                     xfer.Months.since.First.Donation, data=train, 
                    family = binomial(link='logit'))
# Box Cox Transform with Poisson Regression
fit5 <- glm(mydata.Made.Donation.in.March.2007 ~ xfer.Months.since.Last.Donation + 
              xfer.Number.of.Donations + xfer.Total.Volume.Donated..c.c.. + 
              xfer.Months.since.First.Donation, data=train, 
            family = "poisson")
# Model Summary
summary(fit1)
summary(fit2)
summary(fit3)
summary(fit4)
summary(fit5)
# Model Selection Accuracy
#fit1
fit1.results <- predict(fit1,subset(test,select = c(2,3,4,5)),type='response')
fit1.results <- ifelse(fit1.results > 0.5,1,0)
misClasificError <- mean(fit1.results != basetest$Made.Donation.in.March.2007)
print(paste('Base Linear Regression Accuracy',1-misClasificError)) 
#Base Linear Regression Accuracy 0.777777777777778
#fit2
fit2.results <- predict(fit2,subset(test,select = c(2,3,4,5)),type='response')
fit2.results <- ifelse(fit2.results > 0.5,1,0)
misClasificError <- mean(fit2.results != basetest$Made.Donation.in.March.2007)
print(paste('Base Logistic Regression Accuracy',1-misClasificError)) 
#Base Logistic Regression Accuracy 0.777777777777778
#fit3
fit3.results <- predict(fit3,subset(test,select = c(2,3,4,5)),type='response')
fit3.results <- ifelse(fit3.results > 0.5,1,0)
misClasificError <- mean(fit3.results != test$mydata.Made.Donation.in.March.2007)
print(paste('Linear Reg Box Cox Xfrom Accuracy',1-misClasificError)) 
#Linear Reg Box Cox Xfrom Accuracy 0.786458333333333
#fit4
fit4.results <- predict(fit4,subset(test,select = c(2,3,4,5)),type='response')
fit4.results <- ifelse(fit4.results > 0.5,1,0)
misClasificError <- mean(fit4.results != test$mydata.Made.Donation.in.March.2007)
print(paste('Logistic Reg Box Cox Xfrom Accuracy',1-misClasificError)) 
#Logistic Reg Box Cox Xfrom Accuracy 0.765625
#fit5
fit5.results <- predict(fit5,subset(test,select = c(2,3,4,5)),type='response')
fit5.results <- ifelse(fit5.results > 0.5,1,0)
misClasificError <- mean(fit5.results != test$mydata.Made.Donation.in.March.2007)
print(paste('Poisson Regression Accuracy',1-misClasificError)) 
#Poisson Regression Accuracy 0.776041666666667

# Despite the performance of the Linear Model (fit3) we will go with the Logistic Model
# due to to its adherence to regression principals on predicting dichotomist variables 
# and our interpretation of the impact of the sign of the coefficients upon the outcome 
# of the response variable.
print("Selected model is the Linear Regression Model with Box Cox Transformation (Fit3)")
summary(fit3)
CV(fit3)
plot(residuals(fit3))
# Scoring Routine
testdata=read.csv(file.choose(), header=TRUE, na.strings=c(""))
testdata$xfer.Months.since.Last.Donation = (testdata$Months.since.Last.Donation+1)^myt$lambda[1]
testdata$xfer.Number.of.Donations = (testdata$Number.of.Donations+1)^myt$lambda[2]
testdata$xfer.Total.Volume.Donated..c.c.. = (testdata$Total.Volume.Donated..c.c..+1)^myt$lambda[3]
testdata$xfer.Months.since.First.Donation = (testdata$Months.since.First.Donation+1)^myt$lambda[4]
scoredata = subset(testdata, select = c(1,6,7,8,9))
scoredata$Made.Donation.in.March.2007 <- predict(fit3,subset(scoredata,select = c(2,3,4,5)),
                                                 type='response')
scored <- subset(scoredata, select=c(1,6))
write.csv(scored, "/Users/darenpurnell/Documents/Northwestern MSPA/Predict 
          413  Applied Time Series and Forecasting/Midterm/submission.csv")


