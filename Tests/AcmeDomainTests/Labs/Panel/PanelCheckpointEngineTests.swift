@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultPanelCheckpointEngine(Kit.Flags.newRegistry())
        let item = Labs.newPanelCheckpoint("code-925", label: "label-121")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
