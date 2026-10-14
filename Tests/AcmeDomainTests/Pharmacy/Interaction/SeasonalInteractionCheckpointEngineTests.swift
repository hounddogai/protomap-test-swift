@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInteractionCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultSeasonalInteractionCheckpointEngine()
        let item = Pharmacy.newSeasonalInteractionCheckpoint("code-908", name: "name-349")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
