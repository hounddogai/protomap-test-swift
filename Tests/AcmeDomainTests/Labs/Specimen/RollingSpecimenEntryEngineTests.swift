@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingSpecimenEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultRollingSpecimenEntryEngine()
        let item = Labs.newRollingSpecimenEntry("code-894", title: "title-658")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
