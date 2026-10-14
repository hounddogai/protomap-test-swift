@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimTemplateEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultAdaptiveClaimTemplateEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newAdaptiveClaimTemplate("code-537", name: "name-293")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
