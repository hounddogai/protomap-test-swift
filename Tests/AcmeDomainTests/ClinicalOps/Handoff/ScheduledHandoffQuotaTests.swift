@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledHandoffQuotaTests {
    @Test func startsInNew() throws {
        let item = ClinicalOps.newScheduledHandoffQuota("code-512", name: "name-633")
        #expect(item.status == ClinicalOps.ScheduledHandoffQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = ClinicalOps.newScheduledHandoffQuota("code-512", name: "name-633")
        try item.moveTo(ClinicalOps.ScheduledHandoffQuotaStatus.failed)
        #expect(item.status == ClinicalOps.ScheduledHandoffQuotaStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = ClinicalOps.newScheduledHandoffQuota("code-512", name: "name-633")
        item.status = ClinicalOps.ScheduledHandoffQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.ScheduledHandoffQuotaStatus.new) }
    }
}
