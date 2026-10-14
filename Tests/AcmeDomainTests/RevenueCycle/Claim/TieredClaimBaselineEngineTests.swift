@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultTieredClaimBaselineEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newTieredClaimBaseline("code-732", label: "label-465")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
