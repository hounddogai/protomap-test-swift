@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualCourierEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultManualCourierEntryEngine()
        let item = Labs.newManualCourierEntry("code-392", name: "name-914")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
