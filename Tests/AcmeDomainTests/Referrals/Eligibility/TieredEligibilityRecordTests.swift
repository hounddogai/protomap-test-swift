@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredEligibilityRecordTests {
    @Test func startsInIdle() throws {
        let item = Referrals.newTieredEligibilityRecord("code-515", title: "title-431")
        #expect(item.status == Referrals.TieredEligibilityRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Referrals.newTieredEligibilityRecord("code-515", title: "title-431")
        try item.moveTo(Referrals.TieredEligibilityRecordStatus.warming)
        #expect(item.status == Referrals.TieredEligibilityRecordStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Referrals.newTieredEligibilityRecord("code-515", title: "title-431")
        item.status = Referrals.TieredEligibilityRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredEligibilityRecordStatus.idle) }
    }
}
