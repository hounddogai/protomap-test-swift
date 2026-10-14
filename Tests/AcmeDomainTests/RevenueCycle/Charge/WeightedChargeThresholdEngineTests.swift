@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeThresholdEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultWeightedChargeThresholdEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newWeightedChargeThreshold("code-879", name: "name-110")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
