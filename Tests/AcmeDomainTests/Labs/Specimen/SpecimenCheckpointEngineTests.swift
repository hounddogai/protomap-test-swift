@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultSpecimenCheckpointEngine(Kit.Flags.newRegistry())
        let item = Labs.newSpecimenCheckpoint("code-800", label: "label-740")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
