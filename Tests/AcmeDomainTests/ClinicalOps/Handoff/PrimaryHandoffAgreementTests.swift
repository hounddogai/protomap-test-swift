@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryHandoffAgreementTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newPrimaryHandoffAgreement("code-172", title: "title-100")
        #expect(item.status == ClinicalOps.PrimaryHandoffAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newPrimaryHandoffAgreement("code-172", title: "title-100")
        try item.moveTo(ClinicalOps.PrimaryHandoffAgreementStatus.suspended)
        #expect(item.status == ClinicalOps.PrimaryHandoffAgreementStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newPrimaryHandoffAgreement("code-172", title: "title-100")
        item.status = ClinicalOps.PrimaryHandoffAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryHandoffAgreementStatus.draft) }
    }
}
