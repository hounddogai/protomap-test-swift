@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackResultLedgerTests {
    @Test func startsInCreated() throws {
        let item = Labs.newFallbackResultLedger("code-477", name: "name-126")
        #expect(item.status == Labs.FallbackResultLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newFallbackResultLedger("code-477", name: "name-126")
        try item.moveTo(Labs.FallbackResultLedgerStatus.validated)
        #expect(item.status == Labs.FallbackResultLedgerStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newFallbackResultLedger("code-477", name: "name-126")
        item.status = Labs.FallbackResultLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackResultLedgerStatus.created) }
    }
}
