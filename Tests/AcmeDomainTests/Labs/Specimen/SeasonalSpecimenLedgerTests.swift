@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalSpecimenLedgerTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSeasonalSpecimenLedger("code-767", label: "label-512")
        #expect(item.status == Labs.SeasonalSpecimenLedgerStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newSeasonalSpecimenLedger("code-767", label: "label-512")
        try item.moveTo(Labs.SeasonalSpecimenLedgerStatus.closed)
        #expect(item.status == Labs.SeasonalSpecimenLedgerStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSeasonalSpecimenLedger("code-767", label: "label-512")
        item.status = Labs.SeasonalSpecimenLedgerStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalSpecimenLedgerStatus.draft) }
    }
}
