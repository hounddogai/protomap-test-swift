@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixAgreementTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSkillMixAgreement("code-8", title: "title-648")
        #expect(item.status == Staffing.SkillMixAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Staffing.newSkillMixAgreement("code-8", title: "title-648")
        try item.moveTo(Staffing.SkillMixAgreementStatus.closed)
        #expect(item.status == Staffing.SkillMixAgreementStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSkillMixAgreement("code-8", title: "title-648")
        item.status = Staffing.SkillMixAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixAgreementStatus.draft) }
    }
}
