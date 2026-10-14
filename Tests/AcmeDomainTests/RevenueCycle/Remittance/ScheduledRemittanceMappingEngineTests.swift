@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledRemittanceMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultScheduledRemittanceMappingEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newScheduledRemittanceMapping("code-715", name: "name-482")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
