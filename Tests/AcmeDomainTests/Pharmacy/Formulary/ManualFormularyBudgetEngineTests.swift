@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualFormularyBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultManualFormularyBudgetEngine()
        let item = Pharmacy.newManualFormularyBudget("code-78", title: "title-103")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
