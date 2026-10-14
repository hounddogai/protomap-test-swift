@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialDraftTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newCredentialDraft("code-135", title: "title-211")
        #expect(item.status == Staffing.CredentialDraftStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newCredentialDraft("code-135", title: "title-211")
        try item.moveTo(Staffing.CredentialDraftStatus.warming)
        #expect(item.status == Staffing.CredentialDraftStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newCredentialDraft("code-135", title: "title-211")
        item.status = Staffing.CredentialDraftStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialDraftStatus.idle) }
    }
}
