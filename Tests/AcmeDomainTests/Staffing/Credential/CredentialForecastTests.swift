@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialForecastTests {
    @Test func startsInNew() throws {
        let item = Staffing.newCredentialForecast("code-173", title: "title-67")
        #expect(item.status == Staffing.CredentialForecastStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Staffing.newCredentialForecast("code-173", title: "title-67")
        try item.moveTo(Staffing.CredentialForecastStatus.done)
        #expect(item.status == Staffing.CredentialForecastStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newCredentialForecast("code-173", title: "title-67")
        item.status = Staffing.CredentialForecastStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialForecastStatus.new) }
    }
}
