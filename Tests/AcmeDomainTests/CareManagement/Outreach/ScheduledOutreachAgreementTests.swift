@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachAgreementTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newScheduledOutreachAgreement("code-479", title: "title-802")
        #expect(item.status == CareManagement.ScheduledOutreachAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newScheduledOutreachAgreement("code-479", title: "title-802")
        try item.moveTo(CareManagement.ScheduledOutreachAgreementStatus.resolved)
        #expect(item.status == CareManagement.ScheduledOutreachAgreementStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newScheduledOutreachAgreement("code-479", title: "title-802")
        item.status = CareManagement.ScheduledOutreachAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledOutreachAgreementStatus.`open`) }
    }
}
