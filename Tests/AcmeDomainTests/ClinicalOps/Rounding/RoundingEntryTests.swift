@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingEntryTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newRoundingEntry("code-173", label: "label-639")
        #expect(item.status == ClinicalOps.RoundingEntryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newRoundingEntry("code-173", label: "label-639")
        try item.moveTo(ClinicalOps.RoundingEntryStatus.resolved)
        #expect(item.status == ClinicalOps.RoundingEntryStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newRoundingEntry("code-173", label: "label-639")
        item.status = ClinicalOps.RoundingEntryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingEntryStatus.`open`) }
    }
}
