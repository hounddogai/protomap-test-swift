@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledDischargePlanForecastTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newScheduledDischargePlanForecast("code-643", label: "label-170")
        #expect(item.status == BedManagement.ScheduledDischargePlanForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newScheduledDischargePlanForecast("code-643", label: "label-170")
        try item.moveTo(BedManagement.ScheduledDischargePlanForecastStatus.inReview)
        #expect(item.status == BedManagement.ScheduledDischargePlanForecastStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newScheduledDischargePlanForecast("code-643", label: "label-170")
        item.status = BedManagement.ScheduledDischargePlanForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledDischargePlanForecastStatus.`open`) }
    }
}
