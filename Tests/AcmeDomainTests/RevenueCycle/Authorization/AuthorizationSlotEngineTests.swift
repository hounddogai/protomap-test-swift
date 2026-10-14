@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultAuthorizationSlotEngine()
        let item = RevenueCycle.newAuthorizationSlot("code-827", label: "label-608")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
