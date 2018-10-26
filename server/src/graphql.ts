import { ApolloServer, gql } from 'apollo-server'
import { getBook, getBooks, getAuthor } from './data'

const typeDefs = gql`
  type Query {
    book(id: ID!): Book
    books: [Book!]!
  }

  type Book {
    id: ID!
    title: String!
    author: Author!
  }

  type Author {
    id: ID!
    name: String!
    books: [Book!]!
  }
`

const resolvers = {
  Query: {
    async book(parent, { id }, ctx, info) {
      return getBook(id)
    },
    async books(parent, args, ctx, info) {
      return getBooks()
    },
  },
  Book: {
    async author({ id }, args, ctx, info) {
      return getAuthor(id)
    },
  },
  Author: {
    async books({ id }, args, ctx, info) {
      return getBooks({ author: id })
    },
  },
}

// Server

const server = new ApolloServer({
  typeDefs,
  resolvers,
  tracing: true,
})

server
  .listen({
    port: process.env.GRAPHQL_PORT,
  })
  .then(({ url }) => {
    console.log(`Server running on ${url}`)
  })
  .catch(err => {
    throw err
  })
