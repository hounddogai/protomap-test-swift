@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedSpecimenSlotEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultWeightedSpecimenSlotEngine()
        let item = Labs.newWeightedSpecimenSlot("code-893", name: "name-446")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
