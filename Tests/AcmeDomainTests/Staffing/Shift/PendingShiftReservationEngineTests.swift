@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingShiftReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPendingShiftReservationEngine(Kit.Flags.newRegistry())
        let item = Staffing.newPendingShiftReservation("code-545", label: "label-756")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
