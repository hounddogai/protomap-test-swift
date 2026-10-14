@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelScoreEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultScheduledPanelScoreEngine()
        let item = Labs.newScheduledPanelScore("code-812", name: "name-687")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
