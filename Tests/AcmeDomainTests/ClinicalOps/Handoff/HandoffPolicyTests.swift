@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffPolicyTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newHandoffPolicy("code-707", title: "title-694")
        #expect(item.status == ClinicalOps.HandoffPolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = ClinicalOps.newHandoffPolicy("code-707", title: "title-694")
        try item.moveTo(ClinicalOps.HandoffPolicyStatus.ready)
        #expect(item.status == ClinicalOps.HandoffPolicyStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newHandoffPolicy("code-707", title: "title-694")
        item.status = ClinicalOps.HandoffPolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffPolicyStatus.idle) }
    }
}
