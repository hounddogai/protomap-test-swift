@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackReferralMappingTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newFallbackReferralMapping("code-443", label: "label-475")
        #expect(item.status == Referrals.FallbackReferralMappingStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Referrals.newFallbackReferralMapping("code-443", label: "label-475")
        try item.moveTo(Referrals.FallbackReferralMappingStatus.pending)
        #expect(item.status == Referrals.FallbackReferralMappingStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newFallbackReferralMapping("code-443", label: "label-475")
        item.status = Referrals.FallbackReferralMappingStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackReferralMappingStatus.draft) }
    }
}
