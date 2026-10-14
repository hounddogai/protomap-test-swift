@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalCareProtocolSnapshotTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newGlobalCareProtocolSnapshot("code-301", name: "name-632")
        #expect(item.status == ClinicalOps.GlobalCareProtocolSnapshotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newGlobalCareProtocolSnapshot("code-301", name: "name-632")
        try item.moveTo(ClinicalOps.GlobalCareProtocolSnapshotStatus.revoked)
        #expect(item.status == ClinicalOps.GlobalCareProtocolSnapshotStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newGlobalCareProtocolSnapshot("code-301", name: "name-632")
        item.status = ClinicalOps.GlobalCareProtocolSnapshotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalCareProtocolSnapshotStatus.requested) }
    }
}
