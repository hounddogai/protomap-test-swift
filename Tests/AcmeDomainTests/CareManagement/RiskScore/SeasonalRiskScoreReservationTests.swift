@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementSeasonalRiskScoreReservationTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newSeasonalRiskScoreReservation("code-604", label: "label-551")
        #expect(item.status == CareManagement.SeasonalRiskScoreReservationStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newSeasonalRiskScoreReservation("code-604", label: "label-551")
        try item.moveTo(CareManagement.SeasonalRiskScoreReservationStatus.scheduled)
        #expect(item.status == CareManagement.SeasonalRiskScoreReservationStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newSeasonalRiskScoreReservation("code-604", label: "label-551")
        item.status = CareManagement.SeasonalRiskScoreReservationStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.SeasonalRiskScoreReservationStatus.planned) }
    }
}
