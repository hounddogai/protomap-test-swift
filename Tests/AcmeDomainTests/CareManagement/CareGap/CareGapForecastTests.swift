@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapForecastTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newCareGapForecast("code-692", name: "name-105")
        #expect(item.status == CareManagement.CareGapForecastStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newCareGapForecast("code-692", name: "name-105")
        try item.moveTo(CareManagement.CareGapForecastStatus.scheduled)
        #expect(item.status == CareManagement.CareGapForecastStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newCareGapForecast("code-692", name: "name-105")
        item.status = CareManagement.CareGapForecastStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapForecastStatus.planned) }
    }
}
