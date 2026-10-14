@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveRiskScoreItemEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAdaptiveRiskScoreItemEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newAdaptiveRiskScoreItem("code-860", name: "name-803")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
