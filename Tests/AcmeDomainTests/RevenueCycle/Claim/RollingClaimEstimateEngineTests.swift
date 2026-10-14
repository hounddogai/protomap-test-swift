@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultRollingClaimEstimateEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newRollingClaimEstimate("code-37", title: "title-68")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
