@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualReferralMappingTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newManualReferralMapping("code-82", label: "label-380")
        #expect(item.status == Referrals.ManualReferralMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Referrals.newManualReferralMapping("code-82", label: "label-380")
        try item.moveTo(Referrals.ManualReferralMappingStatus.inProgress)
        #expect(item.status == Referrals.ManualReferralMappingStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newManualReferralMapping("code-82", label: "label-380")
        item.status = Referrals.ManualReferralMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualReferralMappingStatus.planned) }
    }
}
