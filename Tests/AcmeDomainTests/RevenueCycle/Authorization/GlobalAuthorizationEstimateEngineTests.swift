@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalAuthorizationEstimateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultGlobalAuthorizationEstimateEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newGlobalAuthorizationEstimate("code-63", name: "name-32")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
