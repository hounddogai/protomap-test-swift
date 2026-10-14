@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualPriorityBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultManualPriorityBudgetEngine(Kit.Flags.newRegistry())
        let item = Imaging.newManualPriorityBudget("code-155", title: "title-14")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
