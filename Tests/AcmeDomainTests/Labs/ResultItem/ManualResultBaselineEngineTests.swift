@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualResultBaselineEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultManualResultBaselineEngine(Kit.Flags.newRegistry())
        let item = Labs.newManualResultBaseline("code-143", name: "name-248")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
