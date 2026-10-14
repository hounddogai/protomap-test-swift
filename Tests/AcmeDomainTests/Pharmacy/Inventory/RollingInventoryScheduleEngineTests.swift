@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventoryScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultRollingInventoryScheduleEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newRollingInventorySchedule("code-599", label: "label-808")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
