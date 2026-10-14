@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachPlanTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newTieredOutreachPlan("code-424", label: "label-686")
        #expect(item.status == CareManagement.TieredOutreachPlanStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newTieredOutreachPlan("code-424", label: "label-686")
        try item.moveTo(CareManagement.TieredOutreachPlanStatus.active)
        #expect(item.status == CareManagement.TieredOutreachPlanStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newTieredOutreachPlan("code-424", label: "label-686")
        item.status = CareManagement.TieredOutreachPlanStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredOutreachPlanStatus.draft) }
    }
}
