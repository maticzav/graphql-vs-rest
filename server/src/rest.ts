import * as express from 'express'
import { getBook, getBooks, getAuthor, getAuthors } from './data'

// Config

const server = express()

// Routes

server.get('/', (req, res) => {
  res.send({
    books: '/books/',
    authors: '/authors/',
  })
})

server.get('/book/:id/', (req, res) => {
  const book = getBook(req.params.id)

  if (book) {
    return res.send({
      id: book.id,
      title: book.id,
      author: `/author/${book.author}/`,
    })
  } else {
    return res.sendStatus(404)
  }
})

server.get('/books/', (req, res) => {
  const books = getBooks()

  res.send(
    books.map(book => {
      return {
        id: book.id,
        title: book.id,
        author: `/author/${book.author}/`,
      }
    }),
  )
})

server.get('/autor/:id/', (req, res) => {
  const author = getAuthor(req.params.id)

  if (author) {
    return res.send({
      id: author.id,
      title: author.id,
      books: author.books.map(id => `/book/${id}/`),
    })
  } else {
    return res.sendStatus(404)
  }
})

server.get('/authors/', (req, res) => {
  const authors = getAuthors()

  res.send(
    authors.map(author => {
      return {
        id: author.id,
        title: author.id,
        books: author.books.map(id => `/book/${id}/`),
      }
    }),
  )
})

// Listen

server.listen(process.env.REST_PORT, err => {
  if (err) throw err
  console.log(`Server running on http://localhost:${process.env.PORT}`)
})
