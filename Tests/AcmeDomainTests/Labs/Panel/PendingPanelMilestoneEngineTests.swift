@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingPanelMilestoneEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPendingPanelMilestoneEngine()
        let item = Labs.newPendingPanelMilestone("code-879", name: "name-483")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
