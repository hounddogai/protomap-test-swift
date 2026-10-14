@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertEntryTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newAlertEntry("code-152", title: "title-716")
        #expect(item.status == ClinicalOps.AlertEntryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newAlertEntry("code-152", title: "title-716")
        try item.moveTo(ClinicalOps.AlertEntryStatus.retired)
        #expect(item.status == ClinicalOps.AlertEntryStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newAlertEntry("code-152", title: "title-716")
        item.status = ClinicalOps.AlertEntryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertEntryStatus.created) }
    }
}
