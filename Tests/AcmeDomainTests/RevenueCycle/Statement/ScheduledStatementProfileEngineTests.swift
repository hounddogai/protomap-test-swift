@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledStatementProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultScheduledStatementProfileEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newScheduledStatementProfile("code-326", name: "name-763")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
