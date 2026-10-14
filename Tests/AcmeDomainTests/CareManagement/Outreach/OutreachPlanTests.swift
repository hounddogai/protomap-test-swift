@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachPlanTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newOutreachPlan("code-817", name: "name-975")
        #expect(item.status == CareManagement.OutreachPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newOutreachPlan("code-817", name: "name-975")
        try item.moveTo(CareManagement.OutreachPlanStatus.granted)
        #expect(item.status == CareManagement.OutreachPlanStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newOutreachPlan("code-817", name: "name-975")
        item.status = CareManagement.OutreachPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachPlanStatus.requested) }
    }
}
