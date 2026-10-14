@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeVarianceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultFallbackReferenceRangeVarianceEngine(Kit.Flags.newRegistry())
        let item = Labs.newFallbackReferenceRangeVariance("code-399", label: "label-960")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
