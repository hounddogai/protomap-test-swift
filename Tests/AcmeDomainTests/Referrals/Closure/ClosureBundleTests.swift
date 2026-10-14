@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureBundleTests {
    @Test func startsInProposed() throws {
        let item = Referrals.newClosureBundle("code-285", title: "title-726")
        #expect(item.status == Referrals.ClosureBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Referrals.newClosureBundle("code-285", title: "title-726")
        try item.moveTo(Referrals.ClosureBundleStatus.rejected)
        #expect(item.status == Referrals.ClosureBundleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Referrals.newClosureBundle("code-285", title: "title-726")
        item.status = Referrals.ClosureBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureBundleStatus.proposed) }
    }
}
