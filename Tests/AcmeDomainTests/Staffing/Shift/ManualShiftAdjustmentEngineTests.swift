@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualShiftAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultManualShiftAdjustmentEngine()
        let item = Staffing.newManualShiftAdjustment("code-777", label: "label-430")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
