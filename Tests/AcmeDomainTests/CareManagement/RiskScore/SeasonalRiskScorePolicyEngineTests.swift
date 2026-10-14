@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScorePolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultSeasonalRiskScorePolicyEngine()
        let item = CareManagement.newSeasonalRiskScorePolicy("code-425", name: "name-501")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
