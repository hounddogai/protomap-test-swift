@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialProfileTests {
    @Test func startsInNew() throws {
        let item = Staffing.newCredentialProfile("code-589", title: "title-630")
        #expect(item.status == Staffing.CredentialProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newCredentialProfile("code-589", title: "title-630")
        try item.moveTo(Staffing.CredentialProfileStatus.running)
        #expect(item.status == Staffing.CredentialProfileStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newCredentialProfile("code-589", title: "title-630")
        item.status = Staffing.CredentialProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialProfileStatus.new) }
    }
}
