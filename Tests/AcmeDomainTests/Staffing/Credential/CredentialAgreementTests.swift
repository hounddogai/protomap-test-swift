@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialAgreementTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCredentialAgreement("code-966", title: "title-527")
        #expect(item.status == Staffing.CredentialAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newCredentialAgreement("code-966", title: "title-527")
        try item.moveTo(Staffing.CredentialAgreementStatus.resolved)
        #expect(item.status == Staffing.CredentialAgreementStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCredentialAgreement("code-966", title: "title-527")
        item.status = Staffing.CredentialAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialAgreementStatus.`open`) }
    }
}
