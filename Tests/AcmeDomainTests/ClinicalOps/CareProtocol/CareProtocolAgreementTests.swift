@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolAgreementTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newCareProtocolAgreement("code-19", title: "title-609")
        #expect(item.status == ClinicalOps.CareProtocolAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = ClinicalOps.newCareProtocolAgreement("code-19", title: "title-609")
        try item.moveTo(ClinicalOps.CareProtocolAgreementStatus.approved)
        #expect(item.status == ClinicalOps.CareProtocolAgreementStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newCareProtocolAgreement("code-19", title: "title-609")
        item.status = ClinicalOps.CareProtocolAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.CareProtocolAgreementStatus.proposed) }
    }
}
