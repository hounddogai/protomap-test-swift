@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimQuotaTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newClaimQuota("code-767", title: "title-310")
        #expect(item.status == RevenueCycle.ClaimQuotaStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newClaimQuota("code-767", title: "title-310")
        try item.moveTo(RevenueCycle.ClaimQuotaStatus.scheduled)
        #expect(item.status == RevenueCycle.ClaimQuotaStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newClaimQuota("code-767", title: "title-310")
        item.status = RevenueCycle.ClaimQuotaStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimQuotaStatus.planned) }
    }
}
