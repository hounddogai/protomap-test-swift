@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultRemittanceEntryEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newRemittanceEntry("code-81", name: "name-149")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
