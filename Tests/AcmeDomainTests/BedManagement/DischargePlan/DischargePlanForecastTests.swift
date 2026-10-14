@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanForecastTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newDischargePlanForecast("code-360", name: "name-127")
        #expect(item.status == BedManagement.DischargePlanForecastStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newDischargePlanForecast("code-360", name: "name-127")
        try item.moveTo(BedManagement.DischargePlanForecastStatus.active)
        #expect(item.status == BedManagement.DischargePlanForecastStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newDischargePlanForecast("code-360", name: "name-127")
        item.status = BedManagement.DischargePlanForecastStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanForecastStatus.draft) }
    }
}
