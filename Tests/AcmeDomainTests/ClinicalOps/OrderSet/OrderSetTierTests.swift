@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetTierTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newOrderSetTier("code-362", label: "label-901")
        #expect(item.status == ClinicalOps.OrderSetTierStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newOrderSetTier("code-362", label: "label-901")
        try item.moveTo(ClinicalOps.OrderSetTierStatus.ready)
        #expect(item.status == ClinicalOps.OrderSetTierStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newOrderSetTier("code-362", label: "label-901")
        item.status = ClinicalOps.OrderSetTierStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetTierStatus.idle) }
    }
}
