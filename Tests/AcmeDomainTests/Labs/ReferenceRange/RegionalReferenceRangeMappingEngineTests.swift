@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRegionalReferenceRangeMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRegionalReferenceRangeMappingEngine(Kit.Flags.newRegistry())
        let item = Labs.newRegionalReferenceRangeMapping("code-563", name: "name-374")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
