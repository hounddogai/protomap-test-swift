@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingCareProtocolAgreementTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newRollingCareProtocolAgreement("code-932", label: "label-669")
        #expect(item.status == ClinicalOps.RollingCareProtocolAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newRollingCareProtocolAgreement("code-932", label: "label-669")
        try item.moveTo(ClinicalOps.RollingCareProtocolAgreementStatus.reopened)
        #expect(item.status == ClinicalOps.RollingCareProtocolAgreementStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newRollingCareProtocolAgreement("code-932", label: "label-669")
        item.status = ClinicalOps.RollingCareProtocolAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RollingCareProtocolAgreementStatus.`open`) }
    }
}
