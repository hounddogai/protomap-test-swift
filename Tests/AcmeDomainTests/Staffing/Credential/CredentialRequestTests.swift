@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRequestTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newCredentialRequest("code-389", title: "title-654")
        #expect(item.status == Staffing.CredentialRequestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newCredentialRequest("code-389", title: "title-654")
        try item.moveTo(Staffing.CredentialRequestStatus.granted)
        #expect(item.status == Staffing.CredentialRequestStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newCredentialRequest("code-389", title: "title-654")
        item.status = Staffing.CredentialRequestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialRequestStatus.requested) }
    }
}
