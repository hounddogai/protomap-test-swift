@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAgreementTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newOutreachAgreement("code-670", title: "title-660")
        #expect(item.status == CareManagement.OutreachAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newOutreachAgreement("code-670", title: "title-660")
        try item.moveTo(CareManagement.OutreachAgreementStatus.suspended)
        #expect(item.status == CareManagement.OutreachAgreementStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newOutreachAgreement("code-670", title: "title-660")
        item.status = CareManagement.OutreachAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachAgreementStatus.draft) }
    }
}
