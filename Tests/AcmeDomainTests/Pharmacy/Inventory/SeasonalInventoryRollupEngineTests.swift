@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInventoryRollupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultSeasonalInventoryRollupEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newSeasonalInventoryRollup("code-406", title: "title-678")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
