@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyClaimBatchTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newLegacyClaimBatch("code-361", title: "title-347")
        #expect(item.status == RevenueCycle.LegacyClaimBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newLegacyClaimBatch("code-361", title: "title-347")
        try item.moveTo(RevenueCycle.LegacyClaimBatchStatus.running)
        #expect(item.status == RevenueCycle.LegacyClaimBatchStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newLegacyClaimBatch("code-361", title: "title-347")
        item.status = RevenueCycle.LegacyClaimBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyClaimBatchStatus.new) }
    }
}
