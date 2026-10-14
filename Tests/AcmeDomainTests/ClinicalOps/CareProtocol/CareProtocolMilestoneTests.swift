@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolMilestoneTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newCareProtocolMilestone("code-145", title: "title-912")
        #expect(item.status == ClinicalOps.CareProtocolMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = ClinicalOps.newCareProtocolMilestone("code-145", title: "title-912")
        try item.moveTo(ClinicalOps.CareProtocolMilestoneStatus.archived)
        #expect(item.status == ClinicalOps.CareProtocolMilestoneStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newCareProtocolMilestone("code-145", title: "title-912")
        item.status = ClinicalOps.CareProtocolMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolMilestoneStatus.`open`) }
    }
}
