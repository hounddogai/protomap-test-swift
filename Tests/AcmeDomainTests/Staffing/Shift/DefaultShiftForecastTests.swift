@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultShiftForecastTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newDefaultShiftForecast("code-801", name: "name-782")
        #expect(item.status == Staffing.DefaultShiftForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Staffing.newDefaultShiftForecast("code-801", name: "name-782")
        try item.moveTo(Staffing.DefaultShiftForecastStatus.scheduled)
        #expect(item.status == Staffing.DefaultShiftForecastStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newDefaultShiftForecast("code-801", name: "name-782")
        item.status = Staffing.DefaultShiftForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultShiftForecastStatus.planned) }
    }
}
