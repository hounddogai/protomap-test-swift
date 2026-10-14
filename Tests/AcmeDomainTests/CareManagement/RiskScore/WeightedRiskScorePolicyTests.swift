@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScorePolicyTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newWeightedRiskScorePolicy("code-910", label: "label-257")
        #expect(item.status == CareManagement.WeightedRiskScorePolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newWeightedRiskScorePolicy("code-910", label: "label-257")
        try item.moveTo(CareManagement.WeightedRiskScorePolicyStatus.draining)
        #expect(item.status == CareManagement.WeightedRiskScorePolicyStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newWeightedRiskScorePolicy("code-910", label: "label-257")
        item.status = CareManagement.WeightedRiskScorePolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedRiskScorePolicyStatus.idle) }
    }
}
