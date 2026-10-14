@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilityEntryTests {
    @Test func startsInDraft() throws {
        let item = Referrals.newEligibilityEntry("code-542", name: "name-842")
        #expect(item.status == Referrals.EligibilityEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Referrals.newEligibilityEntry("code-542", name: "name-842")
        try item.moveTo(Referrals.EligibilityEntryStatus.closed)
        #expect(item.status == Referrals.EligibilityEntryStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Referrals.newEligibilityEntry("code-542", name: "name-842")
        item.status = Referrals.EligibilityEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilityEntryStatus.draft) }
    }
}
