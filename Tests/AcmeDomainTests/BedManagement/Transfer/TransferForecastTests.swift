@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferForecastTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newTransferForecast("code-955", name: "name-384")
        #expect(item.status == BedManagement.TransferForecastStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = BedManagement.newTransferForecast("code-955", name: "name-384")
        try item.moveTo(BedManagement.TransferForecastStatus.revoked)
        #expect(item.status == BedManagement.TransferForecastStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newTransferForecast("code-955", name: "name-384")
        item.status = BedManagement.TransferForecastStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferForecastStatus.requested) }
    }
}
