@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolCheckpointTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newCareProtocolCheckpoint("code-869", name: "name-171")
        #expect(item.status == ClinicalOps.CareProtocolCheckpointStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newCareProtocolCheckpoint("code-869", name: "name-171")
        try item.moveTo(ClinicalOps.CareProtocolCheckpointStatus.validated)
        #expect(item.status == ClinicalOps.CareProtocolCheckpointStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newCareProtocolCheckpoint("code-869", name: "name-171")
        item.status = ClinicalOps.CareProtocolCheckpointStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolCheckpointStatus.created) }
    }
}
