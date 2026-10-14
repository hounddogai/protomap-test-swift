@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingRoundingSlotTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newRollingRoundingSlot("code-964", label: "label-98")
        #expect(item.status == ClinicalOps.RollingRoundingSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = ClinicalOps.newRollingRoundingSlot("code-964", label: "label-98")
        try item.moveTo(ClinicalOps.RollingRoundingSlotStatus.running)
        #expect(item.status == ClinicalOps.RollingRoundingSlotStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newRollingRoundingSlot("code-964", label: "label-98")
        item.status = ClinicalOps.RollingRoundingSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingRoundingSlotStatus.new) }
    }
}
