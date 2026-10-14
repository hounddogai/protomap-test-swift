@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftForecastTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newShiftForecast("code-12", title: "title-948")
        #expect(item.status == Staffing.ShiftForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newShiftForecast("code-12", title: "title-948")
        try item.moveTo(Staffing.ShiftForecastStatus.scheduled)
        #expect(item.status == Staffing.ShiftForecastStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newShiftForecast("code-12", title: "title-948")
        item.status = Staffing.ShiftForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ShiftForecastStatus.planned) }
    }
}
