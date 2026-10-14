@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreEstimateTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newDefaultRiskScoreEstimate("code-451", label: "label-18")
        #expect(item.status == CareManagement.DefaultRiskScoreEstimateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newDefaultRiskScoreEstimate("code-451", label: "label-18")
        try item.moveTo(CareManagement.DefaultRiskScoreEstimateStatus.scheduled)
        #expect(item.status == CareManagement.DefaultRiskScoreEstimateStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newDefaultRiskScoreEstimate("code-451", label: "label-18")
        item.status = CareManagement.DefaultRiskScoreEstimateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultRiskScoreEstimateStatus.planned) }
    }
}
