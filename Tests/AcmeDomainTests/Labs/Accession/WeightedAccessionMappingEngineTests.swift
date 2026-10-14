@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedAccessionMappingEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultWeightedAccessionMappingEngine(Kit.Flags.newRegistry())
        let item = Labs.newWeightedAccessionMapping("code-835", title: "title-235")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
