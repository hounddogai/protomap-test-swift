@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapReservationTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newCareGapReservation("code-667", name: "name-614")
        #expect(item.status == CareManagement.CareGapReservationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = CareManagement.newCareGapReservation("code-667", name: "name-614")
        try item.moveTo(CareManagement.CareGapReservationStatus.queued)
        #expect(item.status == CareManagement.CareGapReservationStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newCareGapReservation("code-667", name: "name-614")
        item.status = CareManagement.CareGapReservationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapReservationStatus.new) }
    }
}
