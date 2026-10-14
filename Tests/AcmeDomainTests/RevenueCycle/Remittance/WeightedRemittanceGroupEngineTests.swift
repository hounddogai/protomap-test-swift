@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedRemittanceGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultWeightedRemittanceGroupEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newWeightedRemittanceGroup("code-754", label: "label-619")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
