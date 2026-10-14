@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingRemittanceEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultRollingRemittanceEstimateEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newRollingRemittanceEstimate("code-566", label: "label-200")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
