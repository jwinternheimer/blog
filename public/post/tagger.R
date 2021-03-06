# load packages
library(keras)


# data collection ---------------------------------------------------------

# load messages
messages <- readRDS("clean_hs_messages.rds")


# one hot encoding --------------------------------------------------------

# get the text of the messages
text <- messages$text

# set maximimum number of words to consider
max_words <- 10000

# create a tokenizer and only consider the top 10000 words
tokenizer <- text_tokenizer(num_words = max_words) %>%
  fit_text_tokenizer(text) 

# turn strings into lists of integer indeces
sequences <- texts_to_sequences(tokenizer, text)

# one-hot encode the text
one_hot_results <- texts_to_matrix(tokenizer, text, mode = "binary")

# this is how we can recover the word index
word_index <- tokenizer$word_index

# define labels
labels <- as.numeric(as.factor(messages$custom_field_label)) - 1

# get number of distinct labels
num_classes <- max(labels) + 1

# convert class vector to binary matrix
label_matrix <- to_categorical(labels, num_classes)


# data partitioning -------------------------------------------------------

# set maximimum number of words to consider
max_words <- 10000

# define labels
labels <- as.numeric(as.factor(messages$custom_field_label)) - 1

# get number of distinct labels
num_classes <- max(labels) + 1

# split data into training and testing sets
indices <- sample(1:nrow(messages))

# define number of training samples
training_samples = round(nrow(messages) * 0.7, 0)
validation_samples = nrow(messages) - training_samples

# set training and testing indeces
training_indices <- indices[1:training_samples]
validation_indices <- indices[(training_samples + 1): (training_samples + validation_samples)]

# create training set
x_train <- one_hot_results[training_indices,]
y_train <- label_matrix[training_indices,]

# create validation set
x_val <- one_hot_results[validation_indices,]
y_val <- label_matrix[validation_indices,]


# model building ----------------------------------------------------------


model <- keras_model_sequential() %>% 
  layer_dense(units = 32, activation = "relu", input_shape = c(max_words)) %>% 
  layer_dropout(rate = 0.3) %>% 
  layer_dense(units = 32, activation = "relu") %>% 
  layer_dropout(rate = 0.2) %>% 
  layer_dense(units = num_classes) %>% 
  layer_activation(activation = 'softmax')

model %>% compile(
  optimizer = "rmsprop",
  loss = "categorical_crossentropy",
  metrics = c("accuracy")
)

model %>% fit(
  one_hot_results, label_matrix,
  batch_size = 256,
  epochs = 10,
  verbose = 1,
  validation_split = 0.3
)

