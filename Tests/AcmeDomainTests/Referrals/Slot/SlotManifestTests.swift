@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotManifestTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newSlotManifest("code-66", name: "name-630")
        #expect(item.status == Referrals.SlotManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Referrals.newSlotManifest("code-66", name: "name-630")
        try item.moveTo(Referrals.SlotManifestStatus.reopened)
        #expect(item.status == Referrals.SlotManifestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newSlotManifest("code-66", name: "name-630")
        item.status = Referrals.SlotManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SlotManifestStatus.`open`) }
    }
}
