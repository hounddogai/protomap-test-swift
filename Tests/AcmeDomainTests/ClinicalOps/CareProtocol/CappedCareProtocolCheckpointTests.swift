@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedCareProtocolCheckpointTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("code-321", title: "title-468")
        #expect(item.status == ClinicalOps.CappedCareProtocolCheckpointStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("code-321", title: "title-468")
        try item.moveTo(ClinicalOps.CappedCareProtocolCheckpointStatus.resolved)
        #expect(item.status == ClinicalOps.CappedCareProtocolCheckpointStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newCappedCareProtocolCheckpoint("code-321", title: "title-468")
        item.status = ClinicalOps.CappedCareProtocolCheckpointStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CappedCareProtocolCheckpointStatus.`open`) }
    }
}
