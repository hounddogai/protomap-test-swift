@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictSpecimenEntryEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultStrictSpecimenEntryEngine()
        let item = Labs.newStrictSpecimenEntry("code-190", name: "name-725")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
