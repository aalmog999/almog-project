from __future__ import annotations

import json
from abc import ABC, abstractmethod
from pathlib import Path

import requests
from pydantic import BaseModel, Field, ValidationError


class Book(BaseModel):
    title: str
    authors: list[str] = Field(default_factory=list)
    first_publish_year: int | None = None
    edition_count: int | None = None
    open_library_key: str | None = None


class OpenLibraryBookItem(BaseModel):
    title: str
    author_name: list[str] = Field(default_factory=list)
    first_publish_year: int | None = None
    edition_count: int | None = None
    key: str | None = None

    def to_book(self) -> Book:
        return Book(
            title=self.title,
            authors=self.author_name,
            first_publish_year=self.first_publish_year,
            edition_count=self.edition_count,
            open_library_key=self.key,
        )


class OpenLibraryResponse(BaseModel):
    num_found: int = Field(alias="numFound")
    docs: list[OpenLibraryBookItem] = Field(default_factory=list)


class BookOutputWriter(ABC):
    @abstractmethod
    def write(self, books: list[Book], output_path: str | Path) -> None:
        pass


class JsonBookOutputWriter(BookOutputWriter):
    def write(self, books: list[Book], output_path: str | Path) -> None:
        output_path = Path(output_path)

        with output_path.open("w", encoding="utf-8") as file:
            json.dump(
                [book.model_dump() for book in books],
                file,
                indent=2,
                ensure_ascii=False,
            )


class OpenLibraryClient:
    BASE_URL = "https://openlibrary.org/search.json"

    HEADERS = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        ),
        "Accept": "application/json,text/plain,*/*",
        "Accept-Language": "en-US,en;q=0.9",
    }

    def search_books(self, query: str, limit: int = 50) -> list[Book]:
        response = requests.get(
            self.BASE_URL,
            params={"q": query},
            headers=self.HEADERS,
            timeout=15,
        )
        response.raise_for_status()

        parsed_response = OpenLibraryResponse.model_validate(response.json())

        return [item.to_book() for item in parsed_response.docs[:limit]]


def filter_books(
    books: list[Book],
    title_keyword: str,
    min_publish_year: int,
) -> list[Book]:
    title_keyword = title_keyword.lower()

    return [
        book
        for book in books
        if title_keyword in book.title.lower()
        and book.first_publish_year is not None
        and book.first_publish_year >= min_publish_year
    ]


def main() -> None:
    query = "python"

    # Filter criteria:
    # 1. Title contains this keyword
    # 2. First publish year is greater than or equal to this year
    title_keyword = "python"
    min_publish_year = 2010

    output_file = "filtered_books.json"

    client = OpenLibraryClient()
    writer: BookOutputWriter = JsonBookOutputWriter()

    try:
        books = client.search_books(query=query, limit=50)

        filtered_books = filter_books(
            books=books,
            title_keyword=title_keyword,
            min_publish_year=min_publish_year,
        )

        writer.write(filtered_books, output_file)

        print(f"Fetched {len(books)} books")
        print(f"Filtered {len(filtered_books)} books")
        print(f"Results written to {output_file}")

    except requests.RequestException as error:
        print(f"API request failed: {error}")

    except ValidationError as error:
        print(f"API response validation failed: {error}")


if __name__ == "__main__":
    main()