@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureBaselineTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newClosureBaseline("code-303", label: "label-518")
        #expect(item.status == Referrals.ClosureBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Referrals.newClosureBaseline("code-303", label: "label-518")
        try item.moveTo(Referrals.ClosureBaselineStatus.active)
        #expect(item.status == Referrals.ClosureBaselineStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newClosureBaseline("code-303", label: "label-518")
        item.status = Referrals.ClosureBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureBaselineStatus.draft) }
    }
}
