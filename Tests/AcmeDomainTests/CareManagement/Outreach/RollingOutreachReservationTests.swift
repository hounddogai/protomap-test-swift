@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingOutreachReservationTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newRollingOutreachReservation("code-720", label: "label-588")
        #expect(item.status == CareManagement.RollingOutreachReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newRollingOutreachReservation("code-720", label: "label-588")
        try item.moveTo(CareManagement.RollingOutreachReservationStatus.granted)
        #expect(item.status == CareManagement.RollingOutreachReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newRollingOutreachReservation("code-720", label: "label-588")
        item.status = CareManagement.RollingOutreachReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingOutreachReservationStatus.requested) }
    }
}
