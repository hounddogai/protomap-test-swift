@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalChargeRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultRegionalChargeRuleEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newRegionalChargeRule("code-161", title: "title-473")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
