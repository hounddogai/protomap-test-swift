@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolReservationTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newFloatPoolReservation("code-72", name: "name-664")
        #expect(item.status == Staffing.FloatPoolReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newFloatPoolReservation("code-72", name: "name-664")
        try item.moveTo(Staffing.FloatPoolReservationStatus.scheduled)
        #expect(item.status == Staffing.FloatPoolReservationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newFloatPoolReservation("code-72", name: "name-664")
        item.status = Staffing.FloatPoolReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolReservationStatus.planned) }
    }
}
