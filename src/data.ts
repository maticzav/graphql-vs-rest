// Data

export interface Book {
  id: string
  title: string
  author: string
}

const books: Book[] = [
  {
    id: 'B1',
    title: 'The Picture of Dorian Gray',
    author: 'A1',
  },
  {
    id: 'B2',
    title: 'The Name of the Rose',
    author: 'A2',
  },
  {
    id: 'B3',
    title: 'A Song of Ice and Fire',
    author: 'A3',
  },
]

export interface Author {
  id: string
  name: string
  books: string[]
}

const authors: Author[] = [
  {
    id: 'A1',
    name: 'Oscar Wilde',
    books: ['B1'],
  },
  {
    id: 'A2',
    name: 'Umberto Eco',
    books: ['B2'],
  },
  {
    id: 'A3',
    name: 'George R. R. Martin',
    books: ['B3'],
  },
]

// function filter

// Functions

export function getBook(id: string): Book {
  return books.find(book => book.id === id)
}

export interface BookWhere {
  id?: string
  title?: string
  author?: string
}

export function getBooks(where: BookWhere = {}): Book[] {
  return books.filter(book => true)
}

export function getAuthor(id: string): Author {
  return authors.find(author => author.id === id)
}

export interface AuthorWhere {
  id?: string
  name?: string
}

export function getAuthors(where: AuthorWhere = {}): Author[] {
  return authors
}
