@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreForecastTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newRiskScoreForecast("code-158", label: "label-8")
        #expect(item.status == CareManagement.RiskScoreForecastStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = CareManagement.newRiskScoreForecast("code-158", label: "label-8")
        try item.moveTo(CareManagement.RiskScoreForecastStatus.retired)
        #expect(item.status == CareManagement.RiskScoreForecastStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newRiskScoreForecast("code-158", label: "label-8")
        item.status = CareManagement.RiskScoreForecastStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreForecastStatus.created) }
    }
}
