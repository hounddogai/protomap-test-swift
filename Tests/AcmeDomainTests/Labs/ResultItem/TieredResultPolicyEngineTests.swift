@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredResultPolicyEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultTieredResultPolicyEngine()
        let item = Labs.newTieredResultPolicy("code-156", title: "title-157")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
