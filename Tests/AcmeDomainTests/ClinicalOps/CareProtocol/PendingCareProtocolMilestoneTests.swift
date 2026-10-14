@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingCareProtocolMilestoneTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newPendingCareProtocolMilestone("code-276", name: "name-439")
        #expect(item.status == ClinicalOps.PendingCareProtocolMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = ClinicalOps.newPendingCareProtocolMilestone("code-276", name: "name-439")
        try item.moveTo(ClinicalOps.PendingCareProtocolMilestoneStatus.resolved)
        #expect(item.status == ClinicalOps.PendingCareProtocolMilestoneStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newPendingCareProtocolMilestone("code-276", name: "name-439")
        item.status = ClinicalOps.PendingCareProtocolMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingCareProtocolMilestoneStatus.`open`) }
    }
}
