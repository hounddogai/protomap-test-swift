@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingRoundingPlanTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newPendingRoundingPlan("code-978", title: "title-573")
        #expect(item.status == ClinicalOps.PendingRoundingPlanStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newPendingRoundingPlan("code-978", title: "title-573")
        try item.moveTo(ClinicalOps.PendingRoundingPlanStatus.published)
        #expect(item.status == ClinicalOps.PendingRoundingPlanStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newPendingRoundingPlan("code-978", title: "title-573")
        item.status = ClinicalOps.PendingRoundingPlanStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingRoundingPlanStatus.created) }
    }
}
