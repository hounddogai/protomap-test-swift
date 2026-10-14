@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLegacyIsolationForecastTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newLegacyIsolationForecast("code-867", name: "name-22")
        #expect(item.status == BedManagement.LegacyIsolationForecastStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = BedManagement.newLegacyIsolationForecast("code-867", name: "name-22")
        try item.moveTo(BedManagement.LegacyIsolationForecastStatus.pending)
        #expect(item.status == BedManagement.LegacyIsolationForecastStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newLegacyIsolationForecast("code-867", name: "name-22")
        item.status = BedManagement.LegacyIsolationForecastStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.LegacyIsolationForecastStatus.draft) }
    }
}
