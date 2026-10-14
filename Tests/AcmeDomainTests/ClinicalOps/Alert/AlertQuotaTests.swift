@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertQuotaTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newAlertQuota("code-157", name: "name-488")
        #expect(item.status == ClinicalOps.AlertQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = ClinicalOps.newAlertQuota("code-157", name: "name-488")
        try item.moveTo(ClinicalOps.AlertQuotaStatus.warming)
        #expect(item.status == ClinicalOps.AlertQuotaStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newAlertQuota("code-157", name: "name-488")
        item.status = ClinicalOps.AlertQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AlertQuotaStatus.idle) }
    }
}
