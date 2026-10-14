@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedAlertPlanTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newWeightedAlertPlan("code-700", title: "title-331")
        #expect(item.status == ClinicalOps.WeightedAlertPlanStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = ClinicalOps.newWeightedAlertPlan("code-700", title: "title-331")
        try item.moveTo(ClinicalOps.WeightedAlertPlanStatus.granted)
        #expect(item.status == ClinicalOps.WeightedAlertPlanStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newWeightedAlertPlan("code-700", title: "title-331")
        item.status = ClinicalOps.WeightedAlertPlanStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedAlertPlanStatus.requested) }
    }
}
