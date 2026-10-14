@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalSlotBatchTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newRegionalSlotBatch("code-109", title: "title-403")
        #expect(item.status == Referrals.RegionalSlotBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newRegionalSlotBatch("code-109", title: "title-403")
        try item.moveTo(Referrals.RegionalSlotBatchStatus.published)
        #expect(item.status == Referrals.RegionalSlotBatchStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newRegionalSlotBatch("code-109", title: "title-403")
        item.status = Referrals.RegionalSlotBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.RegionalSlotBatchStatus.created) }
    }
}
