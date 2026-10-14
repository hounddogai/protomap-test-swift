@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertRequestTests {
    @Test func startsInDraft() throws {
        let item = ClinicalOps.newAlertRequest("code-444", title: "title-645")
        #expect(item.status == ClinicalOps.AlertRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = ClinicalOps.newAlertRequest("code-444", title: "title-645")
        try item.moveTo(ClinicalOps.AlertRequestStatus.suspended)
        #expect(item.status == ClinicalOps.AlertRequestStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = ClinicalOps.newAlertRequest("code-444", title: "title-645")
        item.status = ClinicalOps.AlertRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertRequestStatus.draft) }
    }
}
