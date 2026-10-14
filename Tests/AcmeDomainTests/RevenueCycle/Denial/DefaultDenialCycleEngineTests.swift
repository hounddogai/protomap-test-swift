@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultDenialCycleEngineExtraTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultDefaultDenialCycleEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newDefaultDenialCycle("code-663", title: "title-806")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
