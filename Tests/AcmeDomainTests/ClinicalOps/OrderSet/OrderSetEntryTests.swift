@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetEntryTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newOrderSetEntry("code-351", name: "name-999")
        #expect(item.status == ClinicalOps.OrderSetEntryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newOrderSetEntry("code-351", name: "name-999")
        try item.moveTo(ClinicalOps.OrderSetEntryStatus.reopened)
        #expect(item.status == ClinicalOps.OrderSetEntryStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newOrderSetEntry("code-351", name: "name-999")
        item.status = ClinicalOps.OrderSetEntryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetEntryStatus.`open`) }
    }
}
