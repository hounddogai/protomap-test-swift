@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveAlertRequestTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newAdaptiveAlertRequest("code-976", title: "title-972")
        #expect(item.status == ClinicalOps.AdaptiveAlertRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = ClinicalOps.newAdaptiveAlertRequest("code-976", title: "title-972")
        try item.moveTo(ClinicalOps.AdaptiveAlertRequestStatus.pending)
        #expect(item.status == ClinicalOps.AdaptiveAlertRequestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newAdaptiveAlertRequest("code-976", title: "title-972")
        item.status = ClinicalOps.AdaptiveAlertRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveAlertRequestStatus.draft) }
    }
}
