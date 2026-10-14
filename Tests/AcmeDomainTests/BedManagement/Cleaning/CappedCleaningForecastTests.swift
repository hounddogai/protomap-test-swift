@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedCleaningForecastTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newCappedCleaningForecast("code-889", title: "title-477")
        #expect(item.status == BedManagement.CappedCleaningForecastStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newCappedCleaningForecast("code-889", title: "title-477")
        try item.moveTo(BedManagement.CappedCleaningForecastStatus.warming)
        #expect(item.status == BedManagement.CappedCleaningForecastStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newCappedCleaningForecast("code-889", title: "title-477")
        item.status = BedManagement.CappedCleaningForecastStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedCleaningForecastStatus.idle) }
    }
}
