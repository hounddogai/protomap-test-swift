@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingOvertimeReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultPendingOvertimeReservationEngine(Kit.Flags.newRegistry())
        let item = Staffing.newPendingOvertimeReservation("code-551", title: "title-77")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
