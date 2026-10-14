@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotDigestTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newRegionalSlotDigest("code-306", label: "label-960")
        #expect(item.status == Referrals.RegionalSlotDigestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newRegionalSlotDigest("code-306", label: "label-960")
        try item.moveTo(Referrals.RegionalSlotDigestStatus.granted)
        #expect(item.status == Referrals.RegionalSlotDigestStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newRegionalSlotDigest("code-306", label: "label-960")
        item.status = Referrals.RegionalSlotDigestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalSlotDigestStatus.requested) }
    }
}
