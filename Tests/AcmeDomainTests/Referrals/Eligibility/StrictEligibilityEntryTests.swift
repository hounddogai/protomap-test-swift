@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictEligibilityEntryTests {
    @Test func startsInNew() throws {
        let item = Referrals.newStrictEligibilityEntry("code-15", title: "title-359")
        #expect(item.status == Referrals.StrictEligibilityEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Referrals.newStrictEligibilityEntry("code-15", title: "title-359")
        try item.moveTo(Referrals.StrictEligibilityEntryStatus.done)
        #expect(item.status == Referrals.StrictEligibilityEntryStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newStrictEligibilityEntry("code-15", title: "title-359")
        item.status = Referrals.StrictEligibilityEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictEligibilityEntryStatus.new) }
    }
}
