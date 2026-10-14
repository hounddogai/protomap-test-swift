@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledCareProtocolDigestTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newScheduledCareProtocolDigest("code-963", name: "name-342")
        #expect(item.status == ClinicalOps.ScheduledCareProtocolDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newScheduledCareProtocolDigest("code-963", name: "name-342")
        try item.moveTo(ClinicalOps.ScheduledCareProtocolDigestStatus.queued)
        #expect(item.status == ClinicalOps.ScheduledCareProtocolDigestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newScheduledCareProtocolDigest("code-963", name: "name-342")
        item.status = ClinicalOps.ScheduledCareProtocolDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledCareProtocolDigestStatus.new) }
    }
}
