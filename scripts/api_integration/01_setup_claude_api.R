# Claude API konfiqurasiyası
library(httr)
library(jsonlite)
library(tidyverse)
library(dotenv)

setwd("~/Desktop/Azərbaycan_dili_standartlar")

# .env faylını yükləyirik
load_dot_env()

get_api_key <- function() {
  api_key <- Sys.getenv("ANTHROPIC_API_KEY")
  if(api_key == "") {
    stop("⚠️  ANTHROPIC_API_KEY .env faylında tapılmadı!")
  }
  return(api_key)
}

# Claude API çağırışı
call_claude_api <- function(prompt, system_prompt = NULL) {
  api_key <- get_api_key()
  
  messages <- list(list(role = "user", content = prompt))
  
  body <- list(
    model = "claude-sonnet-4-20250514",
    max_tokens = 4000,
    messages = messages
  )
  
  if(!is.null(system_prompt)) {
    body$system <- system_prompt
  }
  
  response <- POST(
    url = "https://api.anthropic.com/v1/messages",
    add_headers(
      "x-api-key" = api_key,
      "anthropic-version" = "2023-06-01",
      "content-type" = "application/json"
    ),
    body = toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  
  if(status_code(response) != 200) {
    stop("API xətası: ", content(response, "text"))
  }
  
  result <- content(response, "parsed")
  return(result$content[[1]]$text)
}

# Test
test_api <- function() {
  cat("🧪 Claude API test edilir...\n")
  tryCatch({
    response <- call_claude_api("Salam! Bir cümlə cavab ver.")
    cat("✅ API işləyir!\n")
    cat("Cavab:", substr(response, 1, 150), "\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ Xəta:", e$message, "\n")
    return(FALSE)
  })
}

cat("✅ Claude API hazırdır!\n")
