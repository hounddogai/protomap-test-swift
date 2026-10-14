import AcmePlatform
import Foundation
import Testing

@Suite struct KitTextTests {
    @Test func normalizesCaseAndSpace() throws {
        #expect(Kit.Text.normalize("  Mixed Case ") == "mixed case")
    }

    @Test func slugifiesNames() throws {
        #expect(Kit.Text.slugify(" Spring  Sale 2026 ") == "spring-sale-2026")
    }

    @Test func truncatesLongValues() throws {
        #expect(Kit.Text.truncate("abcdefghij", limit: 6) == "abc...")
    }

    @Test func keepsShortValues() throws {
        #expect(Kit.Text.truncate("abc", limit: 6) == "abc")
    }

    @Test func masksAllButTheTail() throws {
        #expect(Kit.Text.maskTail("4111111111111111", keep: 4) == "************1111")
    }

    @Test func countsWords() throws {
        #expect(Kit.Text.wordCount("  one two  three ") == 3)
    }

    @Test func fitsToAWidth() throws {
        #expect(Kit.Text.fit("ab", width: 4) == "ab  ")
    }

    @Test func joinsOnlyNonEmptyParts() throws {
        #expect(Kit.Text.joinNonEmpty(["a", " ", "b"], sep: "/") == "a/b")
        #expect(Kit.Text.containsAny("Late Fee", words: ["fee"]))
    }
}
