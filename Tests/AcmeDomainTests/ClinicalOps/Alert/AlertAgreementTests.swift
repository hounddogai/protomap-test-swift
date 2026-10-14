@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAgreementTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newAlertAgreement("code-955", name: "name-671")
        #expect(item.status == ClinicalOps.AlertAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = ClinicalOps.newAlertAgreement("code-955", name: "name-671")
        try item.moveTo(ClinicalOps.AlertAgreementStatus.queued)
        #expect(item.status == ClinicalOps.AlertAgreementStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newAlertAgreement("code-955", name: "name-671")
        item.status = ClinicalOps.AlertAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertAgreementStatus.new) }
    }
}
