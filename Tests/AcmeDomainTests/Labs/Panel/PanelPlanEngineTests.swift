@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelPlanEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelPlanEngine(Kit.Flags.newRegistry())
        let item = Labs.newPanelPlan("code-923", title: "title-507")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
