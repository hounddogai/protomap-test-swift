@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultAccessionCheckpointEngine(Kit.Flags.newRegistry())
        let item = Labs.newAccessionCheckpoint("code-915", label: "label-64")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
