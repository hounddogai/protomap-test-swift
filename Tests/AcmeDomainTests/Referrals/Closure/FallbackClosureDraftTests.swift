@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureDraftTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newFallbackClosureDraft("code-127", label: "label-649")
        #expect(item.status == Referrals.FallbackClosureDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newFallbackClosureDraft("code-127", label: "label-649")
        try item.moveTo(Referrals.FallbackClosureDraftStatus.granted)
        #expect(item.status == Referrals.FallbackClosureDraftStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newFallbackClosureDraft("code-127", label: "label-649")
        item.status = Referrals.FallbackClosureDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.FallbackClosureDraftStatus.requested) }
    }
}
