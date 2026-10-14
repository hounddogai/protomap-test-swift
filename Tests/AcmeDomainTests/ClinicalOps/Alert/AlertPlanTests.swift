@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertPlanTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newAlertPlan("code-966", title: "title-15")
        #expect(item.status == ClinicalOps.AlertPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newAlertPlan("code-966", title: "title-15")
        try item.moveTo(ClinicalOps.AlertPlanStatus.approved)
        #expect(item.status == ClinicalOps.AlertPlanStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newAlertPlan("code-966", title: "title-15")
        item.status = ClinicalOps.AlertPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertPlanStatus.proposed) }
    }
}
