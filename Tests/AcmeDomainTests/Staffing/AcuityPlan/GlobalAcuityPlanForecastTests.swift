@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalAcuityPlanForecastTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newGlobalAcuityPlanForecast("code-101", label: "label-32")
        #expect(item.status == Staffing.GlobalAcuityPlanForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newGlobalAcuityPlanForecast("code-101", label: "label-32")
        try item.moveTo(Staffing.GlobalAcuityPlanForecastStatus.warming)
        #expect(item.status == Staffing.GlobalAcuityPlanForecastStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newGlobalAcuityPlanForecast("code-101", label: "label-32")
        item.status = Staffing.GlobalAcuityPlanForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalAcuityPlanForecastStatus.idle) }
    }
}
