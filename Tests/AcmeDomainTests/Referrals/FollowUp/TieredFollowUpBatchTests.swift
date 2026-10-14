@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpBatchTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newTieredFollowUpBatch("code-89", title: "title-976")
        #expect(item.status == Referrals.TieredFollowUpBatchStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newTieredFollowUpBatch("code-89", title: "title-976")
        try item.moveTo(Referrals.TieredFollowUpBatchStatus.resolved)
        #expect(item.status == Referrals.TieredFollowUpBatchStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newTieredFollowUpBatch("code-89", title: "title-976")
        item.status = Referrals.TieredFollowUpBatchStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.TieredFollowUpBatchStatus.`open`) }
    }
}
