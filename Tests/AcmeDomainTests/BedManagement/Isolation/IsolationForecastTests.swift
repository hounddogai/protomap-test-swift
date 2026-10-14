@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationForecastTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newIsolationForecast("code-165", name: "name-394")
        #expect(item.status == BedManagement.IsolationForecastStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newIsolationForecast("code-165", name: "name-394")
        try item.moveTo(BedManagement.IsolationForecastStatus.inReview)
        #expect(item.status == BedManagement.IsolationForecastStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newIsolationForecast("code-165", name: "name-394")
        item.status = BedManagement.IsolationForecastStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationForecastStatus.`open`) }
    }
}
