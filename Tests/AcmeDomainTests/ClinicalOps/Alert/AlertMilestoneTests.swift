@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertMilestoneTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newAlertMilestone("code-981", title: "title-672")
        #expect(item.status == ClinicalOps.AlertMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = ClinicalOps.newAlertMilestone("code-981", title: "title-672")
        try item.moveTo(ClinicalOps.AlertMilestoneStatus.validated)
        #expect(item.status == ClinicalOps.AlertMilestoneStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newAlertMilestone("code-981", title: "title-672")
        item.status = ClinicalOps.AlertMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertMilestoneStatus.created) }
    }
}
