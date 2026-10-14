@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachAgreementTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newManualOutreachAgreement("code-368", label: "label-128")
        #expect(item.status == CareManagement.ManualOutreachAgreementStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newManualOutreachAgreement("code-368", label: "label-128")
        try item.moveTo(CareManagement.ManualOutreachAgreementStatus.pending)
        #expect(item.status == CareManagement.ManualOutreachAgreementStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newManualOutreachAgreement("code-368", label: "label-128")
        item.status = CareManagement.ManualOutreachAgreementStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualOutreachAgreementStatus.draft) }
    }
}
