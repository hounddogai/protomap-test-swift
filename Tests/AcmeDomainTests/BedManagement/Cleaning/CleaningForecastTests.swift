@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningForecastTests {
    @Test func startsInPlanned() throws {
        let item = BedManagement.newCleaningForecast("code-764", name: "name-569")
        #expect(item.status == BedManagement.CleaningForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = BedManagement.newCleaningForecast("code-764", name: "name-569")
        try item.moveTo(BedManagement.CleaningForecastStatus.scheduled)
        #expect(item.status == BedManagement.CleaningForecastStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = BedManagement.newCleaningForecast("code-764", name: "name-569")
        item.status = BedManagement.CleaningForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningForecastStatus.planned) }
    }
}
