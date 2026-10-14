@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingResultRuleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingResultRuleEngine(Kit.Flags.newRegistry())
        let item = Labs.newPendingResultRule("code-92", name: "name-465")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
