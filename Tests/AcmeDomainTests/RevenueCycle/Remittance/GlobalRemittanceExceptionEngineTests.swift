@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalRemittanceExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultGlobalRemittanceExceptionEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newGlobalRemittanceException("code-999", name: "name-750")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
