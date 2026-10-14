@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScoreTemplateTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newWeightedRiskScoreTemplate("code-875", name: "name-2")
        #expect(item.status == CareManagement.WeightedRiskScoreTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newWeightedRiskScoreTemplate("code-875", name: "name-2")
        try item.moveTo(CareManagement.WeightedRiskScoreTemplateStatus.scheduled)
        #expect(item.status == CareManagement.WeightedRiskScoreTemplateStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newWeightedRiskScoreTemplate("code-875", name: "name-2")
        item.status = CareManagement.WeightedRiskScoreTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedRiskScoreTemplateStatus.planned) }
    }
}
