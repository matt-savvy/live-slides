File.exists?(Path.expand("~/.iex.exs")) && import_file("~/.iex.exs")

import LiveSlides.AccountsFixtures
import LiveSlides.PresentationsFixtures

alias LiveSlides.Repo
alias LiveSlides.Accounts
alias LiveSlides.Presentations
alias LiveSlides.Presentations.Deck
alias LiveSlides.Presentations.Deck.Slide
