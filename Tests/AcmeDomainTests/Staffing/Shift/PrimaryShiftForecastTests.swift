@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftForecastTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newPrimaryShiftForecast("code-469", label: "label-951")
        #expect(item.status == Staffing.PrimaryShiftForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newPrimaryShiftForecast("code-469", label: "label-951")
        try item.moveTo(Staffing.PrimaryShiftForecastStatus.ready)
        #expect(item.status == Staffing.PrimaryShiftForecastStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newPrimaryShiftForecast("code-469", label: "label-951")
        item.status = Staffing.PrimaryShiftForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryShiftForecastStatus.idle) }
    }
}
