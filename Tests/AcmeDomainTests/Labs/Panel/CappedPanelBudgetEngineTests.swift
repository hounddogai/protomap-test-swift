@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCappedPanelBudgetEngine(Kit.Flags.newRegistry())
        let item = Labs.newCappedPanelBudget("code-425", title: "title-472")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
