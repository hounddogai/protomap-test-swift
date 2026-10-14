@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictBedBoardForecastTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newStrictBedBoardForecast("code-95", label: "label-866")
        #expect(item.status == BedManagement.StrictBedBoardForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newStrictBedBoardForecast("code-95", label: "label-866")
        try item.moveTo(BedManagement.StrictBedBoardForecastStatus.approved)
        #expect(item.status == BedManagement.StrictBedBoardForecastStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newStrictBedBoardForecast("code-95", label: "label-866")
        item.status = BedManagement.StrictBedBoardForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictBedBoardForecastStatus.proposed) }
    }
}
