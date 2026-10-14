@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialTemplateTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCredentialTemplate("code-988", name: "name-709")
        #expect(item.status == Staffing.CredentialTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Staffing.newCredentialTemplate("code-988", name: "name-709")
        try item.moveTo(Staffing.CredentialTemplateStatus.reopened)
        #expect(item.status == Staffing.CredentialTemplateStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCredentialTemplate("code-988", name: "name-709")
        item.status = Staffing.CredentialTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialTemplateStatus.`open`) }
    }
}
