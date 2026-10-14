@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultStatementPreferenceEngine()
        let item = RevenueCycle.newStatementPreference("code-482", name: "name-888")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
