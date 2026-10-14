@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsGlobalHandoffQuotaTests {
    @Test func startsInIdle() throws {
        let item = ClinicalOps.newGlobalHandoffQuota("code-837", title: "title-334")
        #expect(item.status == ClinicalOps.GlobalHandoffQuotaStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = ClinicalOps.newGlobalHandoffQuota("code-837", title: "title-334")
        try item.moveTo(ClinicalOps.GlobalHandoffQuotaStatus.stopped)
        #expect(item.status == ClinicalOps.GlobalHandoffQuotaStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = ClinicalOps.newGlobalHandoffQuota("code-837", title: "title-334")
        item.status = ClinicalOps.GlobalHandoffQuotaStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.GlobalHandoffQuotaStatus.idle) }
    }
}
