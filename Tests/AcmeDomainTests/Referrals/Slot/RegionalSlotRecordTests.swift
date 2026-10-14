@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotRecordTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newRegionalSlotRecord("code-461", name: "name-740")
        #expect(item.status == Referrals.RegionalSlotRecordStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newRegionalSlotRecord("code-461", name: "name-740")
        try item.moveTo(Referrals.RegionalSlotRecordStatus.inReview)
        #expect(item.status == Referrals.RegionalSlotRecordStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newRegionalSlotRecord("code-461", name: "name-740")
        item.status = Referrals.RegionalSlotRecordStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalSlotRecordStatus.`open`) }
    }
}
