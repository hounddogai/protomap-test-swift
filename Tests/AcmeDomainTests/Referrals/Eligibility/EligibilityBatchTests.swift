@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityBatchTests {
    @Test func startsInNew() throws {
        let item = Referrals.newEligibilityBatch("code-947", title: "title-639")
        #expect(item.status == Referrals.EligibilityBatchStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newEligibilityBatch("code-947", title: "title-639")
        try item.moveTo(Referrals.EligibilityBatchStatus.running)
        #expect(item.status == Referrals.EligibilityBatchStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newEligibilityBatch("code-947", title: "title-639")
        item.status = Referrals.EligibilityBatchStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityBatchStatus.new) }
    }
}
