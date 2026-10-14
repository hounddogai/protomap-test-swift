@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialBaselineTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newCredentialBaseline("code-263", title: "title-472")
        #expect(item.status == Staffing.CredentialBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newCredentialBaseline("code-263", title: "title-472")
        try item.moveTo(Staffing.CredentialBaselineStatus.validated)
        #expect(item.status == Staffing.CredentialBaselineStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newCredentialBaseline("code-263", title: "title-472")
        item.status = Staffing.CredentialBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialBaselineStatus.created) }
    }
}
