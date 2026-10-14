@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotMappingTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newSlotMapping("code-965", title: "title-302")
        #expect(item.status == Referrals.SlotMappingStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newSlotMapping("code-965", title: "title-302")
        try item.moveTo(Referrals.SlotMappingStatus.reopened)
        #expect(item.status == Referrals.SlotMappingStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newSlotMapping("code-965", title: "title-302")
        item.status = Referrals.SlotMappingStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotMappingStatus.`open`) }
    }
}
