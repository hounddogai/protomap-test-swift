@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingBatchedOvertimeReservationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultBatchedOvertimeReservationEngine()
        let item = Staffing.newBatchedOvertimeReservation("code-698", title: "title-455")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
