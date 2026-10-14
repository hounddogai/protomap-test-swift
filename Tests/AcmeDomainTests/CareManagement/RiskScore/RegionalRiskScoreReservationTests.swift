@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalRiskScoreReservationTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRegionalRiskScoreReservation("code-972", name: "name-458")
        #expect(item.status == CareManagement.RegionalRiskScoreReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newRegionalRiskScoreReservation("code-972", name: "name-458")
        try item.moveTo(CareManagement.RegionalRiskScoreReservationStatus.inProgress)
        #expect(item.status == CareManagement.RegionalRiskScoreReservationStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRegionalRiskScoreReservation("code-972", name: "name-458")
        item.status = CareManagement.RegionalRiskScoreReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalRiskScoreReservationStatus.planned) }
    }
}
