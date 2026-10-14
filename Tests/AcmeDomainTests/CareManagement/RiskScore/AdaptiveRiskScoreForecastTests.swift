@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreForecastTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newAdaptiveRiskScoreForecast("code-273", name: "name-685")
        #expect(item.status == CareManagement.AdaptiveRiskScoreForecastStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newAdaptiveRiskScoreForecast("code-273", name: "name-685")
        try item.moveTo(CareManagement.AdaptiveRiskScoreForecastStatus.active)
        #expect(item.status == CareManagement.AdaptiveRiskScoreForecastStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newAdaptiveRiskScoreForecast("code-273", name: "name-685")
        item.status = CareManagement.AdaptiveRiskScoreForecastStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveRiskScoreForecastStatus.draft) }
    }
}
