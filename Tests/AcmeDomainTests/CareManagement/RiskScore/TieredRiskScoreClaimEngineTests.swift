@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredRiskScoreClaimEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultTieredRiskScoreClaimEngine()
        let item = CareManagement.newTieredRiskScoreClaim("code-870", name: "name-462")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
