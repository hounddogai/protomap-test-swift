@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialTargetTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newCredentialTarget("code-199", title: "title-29")
        #expect(item.status == Staffing.CredentialTargetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newCredentialTarget("code-199", title: "title-29")
        try item.moveTo(Staffing.CredentialTargetStatus.granted)
        #expect(item.status == Staffing.CredentialTargetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newCredentialTarget("code-199", title: "title-29")
        item.status = Staffing.CredentialTargetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialTargetStatus.requested) }
    }
}
