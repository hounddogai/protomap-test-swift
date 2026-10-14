@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRiskScoreReservationTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRiskScoreReservation("code-503", title: "title-472")
        #expect(item.status == CareManagement.RiskScoreReservationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newRiskScoreReservation("code-503", title: "title-472")
        try item.moveTo(CareManagement.RiskScoreReservationStatus.suspended)
        #expect(item.status == CareManagement.RiskScoreReservationStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRiskScoreReservation("code-503", title: "title-472")
        item.status = CareManagement.RiskScoreReservationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RiskScoreReservationStatus.draft) }
    }
}
