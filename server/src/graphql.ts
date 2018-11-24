import { ApolloServer, gql } from 'apollo-server'

const typeDefs = gql`
  type Query {
    test(token: String!): TestPayload!
  }

  type TestPayload {
    token: String!
    query: Query!
  }
`

const resolvers = {
  Query: {
    async test(parent, { token }, ctx, info) {
      return {
        token,
        query: {},
      }
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
    console.log(`GraphQL running on ${url}`)
  })
  .catch(err => {
    throw err
  })
