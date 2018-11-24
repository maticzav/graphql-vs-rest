import * as express from 'express'

// Config

const server = express()

// Routes

server.get('/', (req, res) => {
  res.send({
    links: {
      test: '/test/',
    },
  })
})

server.get('/test/:token/', (req, res) => {
  return res.send({
    token: req.params.token,
    links: {
      test: '/test/',
    },
  })
})

// Listen

server.listen({ port: process.env.REST_PORT }, err => {
  if (err) throw err
  console.log(`REST running on http://localhost:${process.env.REST_PORT}`)
})
