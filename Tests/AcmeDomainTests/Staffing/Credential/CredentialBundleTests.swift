@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialBundleTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newCredentialBundle("code-885", name: "name-614")
        #expect(item.status == Staffing.CredentialBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newCredentialBundle("code-885", name: "name-614")
        try item.moveTo(Staffing.CredentialBundleStatus.active)
        #expect(item.status == Staffing.CredentialBundleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newCredentialBundle("code-885", name: "name-614")
        item.status = Staffing.CredentialBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialBundleStatus.draft) }
    }
}
