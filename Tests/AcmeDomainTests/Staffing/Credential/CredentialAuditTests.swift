@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialAuditTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCredentialAudit("code-792", title: "title-726")
        #expect(item.status == Staffing.CredentialAuditStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Staffing.newCredentialAudit("code-792", title: "title-726")
        try item.moveTo(Staffing.CredentialAuditStatus.archived)
        #expect(item.status == Staffing.CredentialAuditStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCredentialAudit("code-792", title: "title-726")
        item.status = Staffing.CredentialAuditStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialAuditStatus.`open`) }
    }
}
