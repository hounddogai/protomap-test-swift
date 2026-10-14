@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRuleTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCredentialRule("code-624", title: "title-253")
        #expect(item.status == Staffing.CredentialRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newCredentialRule("code-624", title: "title-253")
        try item.moveTo(Staffing.CredentialRuleStatus.inReview)
        #expect(item.status == Staffing.CredentialRuleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCredentialRule("code-624", title: "title-253")
        item.status = Staffing.CredentialRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialRuleStatus.`open`) }
    }
}
