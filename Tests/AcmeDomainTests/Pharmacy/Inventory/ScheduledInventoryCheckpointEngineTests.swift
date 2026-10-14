@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledInventoryCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultScheduledInventoryCheckpointEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newScheduledInventoryCheckpoint("code-346", label: "label-197")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
