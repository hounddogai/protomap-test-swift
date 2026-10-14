@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBudgetEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultReferenceRangeBudgetEngine(Kit.Flags.newRegistry())
        let item = Labs.newReferenceRangeBudget("code-738", label: "label-22")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
