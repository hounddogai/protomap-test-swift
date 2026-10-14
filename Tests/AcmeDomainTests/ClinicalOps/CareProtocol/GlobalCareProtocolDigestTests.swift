@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolDigestTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newGlobalCareProtocolDigest("code-270", title: "title-700")
        #expect(item.status == ClinicalOps.GlobalCareProtocolDigestStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newGlobalCareProtocolDigest("code-270", title: "title-700")
        try item.moveTo(ClinicalOps.GlobalCareProtocolDigestStatus.warming)
        #expect(item.status == ClinicalOps.GlobalCareProtocolDigestStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newGlobalCareProtocolDigest("code-270", title: "title-700")
        item.status = ClinicalOps.GlobalCareProtocolDigestStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalCareProtocolDigestStatus.idle) }
    }
}
