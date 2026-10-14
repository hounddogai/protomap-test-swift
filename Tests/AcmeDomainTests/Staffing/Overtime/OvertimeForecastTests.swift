@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeForecastTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newOvertimeForecast("code-183", label: "label-447")
        #expect(item.status == Staffing.OvertimeForecastStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newOvertimeForecast("code-183", label: "label-447")
        try item.moveTo(Staffing.OvertimeForecastStatus.granted)
        #expect(item.status == Staffing.OvertimeForecastStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newOvertimeForecast("code-183", label: "label-447")
        item.status = Staffing.OvertimeForecastStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeForecastStatus.requested) }
    }
}
