@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureManifestTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newClosureManifest("code-393", title: "title-335")
        #expect(item.status == Referrals.ClosureManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Referrals.newClosureManifest("code-393", title: "title-335")
        try item.moveTo(Referrals.ClosureManifestStatus.expired)
        #expect(item.status == Referrals.ClosureManifestStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newClosureManifest("code-393", title: "title-335")
        item.status = Referrals.ClosureManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureManifestStatus.requested) }
    }
}
