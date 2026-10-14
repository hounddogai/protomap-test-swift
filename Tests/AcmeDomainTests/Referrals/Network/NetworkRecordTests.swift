@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkRecordTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newNetworkRecord("code-551", name: "name-270")
        #expect(item.status == Referrals.NetworkRecordStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newNetworkRecord("code-551", name: "name-270")
        try item.moveTo(Referrals.NetworkRecordStatus.published)
        #expect(item.status == Referrals.NetworkRecordStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newNetworkRecord("code-551", name: "name-270")
        item.status = Referrals.NetworkRecordStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.NetworkRecordStatus.created) }
    }
}
