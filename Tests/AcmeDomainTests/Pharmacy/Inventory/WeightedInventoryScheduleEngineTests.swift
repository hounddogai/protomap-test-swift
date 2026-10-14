@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInventoryScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultWeightedInventoryScheduleEngine()
        let item = Pharmacy.newWeightedInventorySchedule("code-882", label: "label-183")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
