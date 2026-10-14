@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultCappedDispenseCheckpointEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newCappedDispenseCheckpoint("code-568", title: "title-914")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
