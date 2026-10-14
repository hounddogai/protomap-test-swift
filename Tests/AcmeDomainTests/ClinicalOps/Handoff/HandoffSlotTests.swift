@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffSlotTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newHandoffSlot("code-809", name: "name-361")
        #expect(item.status == ClinicalOps.HandoffSlotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = ClinicalOps.newHandoffSlot("code-809", name: "name-361")
        try item.moveTo(ClinicalOps.HandoffSlotStatus.scheduled)
        #expect(item.status == ClinicalOps.HandoffSlotStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newHandoffSlot("code-809", name: "name-361")
        item.status = ClinicalOps.HandoffSlotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffSlotStatus.planned) }
    }
}
