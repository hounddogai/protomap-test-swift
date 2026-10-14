@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingAlertQuotaTests {
    @Test func startsInPlanned() throws {
        let item = ClinicalOps.newPendingAlertQuota("code-152", title: "title-269")
        #expect(item.status == ClinicalOps.PendingAlertQuotaStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = ClinicalOps.newPendingAlertQuota("code-152", title: "title-269")
        try item.moveTo(ClinicalOps.PendingAlertQuotaStatus.completed)
        #expect(item.status == ClinicalOps.PendingAlertQuotaStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = ClinicalOps.newPendingAlertQuota("code-152", title: "title-269")
        item.status = ClinicalOps.PendingAlertQuotaStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PendingAlertQuotaStatus.planned) }
    }
}
