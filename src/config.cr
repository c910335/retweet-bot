require "yaml"

class Config
  YAML.mapping(
    rules: Array(Retweet)
  )

  class Retweet
    YAML.mapping(
      name: String,
      text: String
    )
  end
end
