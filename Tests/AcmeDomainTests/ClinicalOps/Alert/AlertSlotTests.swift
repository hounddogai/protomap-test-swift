@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertSlotTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newAlertSlot("code-159", title: "title-917")
        #expect(item.status == ClinicalOps.AlertSlotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newAlertSlot("code-159", title: "title-917")
        try item.moveTo(ClinicalOps.AlertSlotStatus.published)
        #expect(item.status == ClinicalOps.AlertSlotStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newAlertSlot("code-159", title: "title-917")
        item.status = ClinicalOps.AlertSlotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertSlotStatus.created) }
    }
}
