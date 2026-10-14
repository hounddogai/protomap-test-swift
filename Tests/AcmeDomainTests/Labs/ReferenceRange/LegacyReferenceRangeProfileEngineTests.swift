@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyReferenceRangeProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultLegacyReferenceRangeProfileEngine(Kit.Flags.newRegistry())
        let item = Labs.newLegacyReferenceRangeProfile("code-626", label: "label-271")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
