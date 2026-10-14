@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultOutreachPlanTests {
    @Test func startsInProposed() throws {
        let item = CareManagement.newDefaultOutreachPlan("code-176", title: "title-680")
        #expect(item.status == CareManagement.DefaultOutreachPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = CareManagement.newDefaultOutreachPlan("code-176", title: "title-680")
        try item.moveTo(CareManagement.DefaultOutreachPlanStatus.approved)
        #expect(item.status == CareManagement.DefaultOutreachPlanStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = CareManagement.newDefaultOutreachPlan("code-176", title: "title-680")
        item.status = CareManagement.DefaultOutreachPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultOutreachPlanStatus.proposed) }
    }
}
