@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultWeightedCourierExceptionEngine(Kit.Flags.newRegistry())
        let item = Labs.newWeightedCourierException("code-118", label: "label-277")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
