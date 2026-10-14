@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAdaptiveRiskScoreThresholdEngine()
        let item = CareManagement.newAdaptiveRiskScoreThreshold("code-503", title: "title-274")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
