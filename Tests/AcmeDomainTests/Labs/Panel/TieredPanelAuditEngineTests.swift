@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultTieredPanelAuditEngine()
        let item = Labs.newTieredPanelAudit("code-681", name: "name-424")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
