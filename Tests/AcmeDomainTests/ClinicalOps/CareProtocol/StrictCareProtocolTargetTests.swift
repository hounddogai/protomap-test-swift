@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsStrictCareProtocolTargetTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newStrictCareProtocolTarget("code-714", label: "label-925")
        #expect(item.status == ClinicalOps.StrictCareProtocolTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = ClinicalOps.newStrictCareProtocolTarget("code-714", label: "label-925")
        try item.moveTo(ClinicalOps.StrictCareProtocolTargetStatus.draining)
        #expect(item.status == ClinicalOps.StrictCareProtocolTargetStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newStrictCareProtocolTarget("code-714", label: "label-925")
        item.status = ClinicalOps.StrictCareProtocolTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.StrictCareProtocolTargetStatus.idle) }
    }
}
