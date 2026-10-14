@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialReservationTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newCredentialReservation("code-617", title: "title-500")
        #expect(item.status == Staffing.CredentialReservationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newCredentialReservation("code-617", title: "title-500")
        try item.moveTo(Staffing.CredentialReservationStatus.granted)
        #expect(item.status == Staffing.CredentialReservationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newCredentialReservation("code-617", title: "title-500")
        item.status = Staffing.CredentialReservationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialReservationStatus.requested) }
    }
}
