@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentEstimateTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newTieredAssessmentEstimate("code-588", label: "label-417")
        #expect(item.status == CareManagement.TieredAssessmentEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newTieredAssessmentEstimate("code-588", label: "label-417")
        try item.moveTo(CareManagement.TieredAssessmentEstimateStatus.warming)
        #expect(item.status == CareManagement.TieredAssessmentEstimateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newTieredAssessmentEstimate("code-588", label: "label-417")
        item.status = CareManagement.TieredAssessmentEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredAssessmentEstimateStatus.idle) }
    }
}
