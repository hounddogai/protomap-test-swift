@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialGroupTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCredentialGroup("code-288", name: "name-620")
        #expect(item.status == Staffing.CredentialGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newCredentialGroup("code-288", name: "name-620")
        try item.moveTo(Staffing.CredentialGroupStatus.resolved)
        #expect(item.status == Staffing.CredentialGroupStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCredentialGroup("code-288", name: "name-620")
        item.status = Staffing.CredentialGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialGroupStatus.`open`) }
    }
}
