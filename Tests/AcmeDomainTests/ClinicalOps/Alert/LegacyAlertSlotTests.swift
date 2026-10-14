@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyAlertSlotTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newLegacyAlertSlot("code-39", label: "label-577")
        #expect(item.status == ClinicalOps.LegacyAlertSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = ClinicalOps.newLegacyAlertSlot("code-39", label: "label-577")
        try item.moveTo(ClinicalOps.LegacyAlertSlotStatus.active)
        #expect(item.status == ClinicalOps.LegacyAlertSlotStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newLegacyAlertSlot("code-39", label: "label-577")
        item.status = ClinicalOps.LegacyAlertSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyAlertSlotStatus.draft) }
    }
}
