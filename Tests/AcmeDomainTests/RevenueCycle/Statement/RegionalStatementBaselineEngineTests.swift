@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalStatementBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultRegionalStatementBaselineEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newRegionalStatementBaseline("code-544", label: "label-902")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
