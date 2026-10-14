@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureEntryTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newClosureEntry("code-87", label: "label-24")
        #expect(item.status == Referrals.ClosureEntryStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newClosureEntry("code-87", label: "label-24")
        try item.moveTo(Referrals.ClosureEntryStatus.inReview)
        #expect(item.status == Referrals.ClosureEntryStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newClosureEntry("code-87", label: "label-24")
        item.status = Referrals.ClosureEntryStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ClosureEntryStatus.`open`) }
    }
}
