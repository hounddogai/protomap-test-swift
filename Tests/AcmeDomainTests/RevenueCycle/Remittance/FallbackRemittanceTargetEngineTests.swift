@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceTargetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultFallbackRemittanceTargetEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newFallbackRemittanceTarget("code-753", title: "title-87")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
