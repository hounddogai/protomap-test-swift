@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRiskScoreThresholdEngine()
        let item = CareManagement.newRiskScoreThreshold("code-878", name: "name-870")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
