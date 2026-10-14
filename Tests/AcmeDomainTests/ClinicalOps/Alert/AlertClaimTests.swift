@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertClaimTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newAlertClaim("code-434", title: "title-146")
        #expect(item.status == ClinicalOps.AlertClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newAlertClaim("code-434", title: "title-146")
        try item.moveTo(ClinicalOps.AlertClaimStatus.suspended)
        #expect(item.status == ClinicalOps.AlertClaimStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newAlertClaim("code-434", title: "title-146")
        item.status = ClinicalOps.AlertClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertClaimStatus.draft) }
    }
}
