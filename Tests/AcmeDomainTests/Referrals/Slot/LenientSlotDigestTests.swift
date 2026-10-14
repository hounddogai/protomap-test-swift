@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientSlotDigestTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newLenientSlotDigest("code-959", title: "title-316")
        #expect(item.status == Referrals.LenientSlotDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newLenientSlotDigest("code-959", title: "title-316")
        try item.moveTo(Referrals.LenientSlotDigestStatus.validated)
        #expect(item.status == Referrals.LenientSlotDigestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newLenientSlotDigest("code-959", title: "title-316")
        item.status = Referrals.LenientSlotDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientSlotDigestStatus.created) }
    }
}
