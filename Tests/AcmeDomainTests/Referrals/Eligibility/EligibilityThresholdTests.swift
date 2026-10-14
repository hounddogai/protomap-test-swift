@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityThresholdTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newEligibilityThreshold("code-159", label: "label-183")
        #expect(item.status == Referrals.EligibilityThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Referrals.newEligibilityThreshold("code-159", label: "label-183")
        try item.moveTo(Referrals.EligibilityThresholdStatus.draining)
        #expect(item.status == Referrals.EligibilityThresholdStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newEligibilityThreshold("code-159", label: "label-183")
        item.status = Referrals.EligibilityThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityThresholdStatus.idle) }
    }
}
