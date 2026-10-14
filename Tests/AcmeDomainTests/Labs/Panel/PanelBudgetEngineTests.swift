@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelBudgetEngine()
        let item = Labs.newPanelBudget("code-86", title: "title-572")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
