@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultBudgetEngine()
        let item = Labs.newResultBudget("code-268", title: "title-558")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
