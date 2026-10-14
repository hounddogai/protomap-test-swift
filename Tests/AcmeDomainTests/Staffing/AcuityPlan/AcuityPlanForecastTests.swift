@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanForecastTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newAcuityPlanForecast("code-499", title: "title-295")
        #expect(item.status == Staffing.AcuityPlanForecastStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Staffing.newAcuityPlanForecast("code-499", title: "title-295")
        try item.moveTo(Staffing.AcuityPlanForecastStatus.suspended)
        #expect(item.status == Staffing.AcuityPlanForecastStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newAcuityPlanForecast("code-499", title: "title-295")
        item.status = Staffing.AcuityPlanForecastStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AcuityPlanForecastStatus.draft) }
    }
}
