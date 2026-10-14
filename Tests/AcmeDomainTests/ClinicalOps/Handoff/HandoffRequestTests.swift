@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsHandoffRequestTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newHandoffRequest("code-28", name: "name-117")
        #expect(item.status == ClinicalOps.HandoffRequestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newHandoffRequest("code-28", name: "name-117")
        try item.moveTo(ClinicalOps.HandoffRequestStatus.warming)
        #expect(item.status == ClinicalOps.HandoffRequestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newHandoffRequest("code-28", name: "name-117")
        item.status = ClinicalOps.HandoffRequestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.HandoffRequestStatus.idle) }
    }
}
