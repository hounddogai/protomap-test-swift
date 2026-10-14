@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetRollupTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newCappedOrderSetRollup("code-100", label: "label-410")
        #expect(item.status == ClinicalOps.CappedOrderSetRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newCappedOrderSetRollup("code-100", label: "label-410")
        try item.moveTo(ClinicalOps.CappedOrderSetRollupStatus.ready)
        #expect(item.status == ClinicalOps.CappedOrderSetRollupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newCappedOrderSetRollup("code-100", label: "label-410")
        item.status = ClinicalOps.CappedOrderSetRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedOrderSetRollupStatus.idle) }
    }
}
