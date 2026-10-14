@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLenientNetworkSnapshotTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newLenientNetworkSnapshot("code-372", name: "name-711")
        #expect(item.status == Referrals.LenientNetworkSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Referrals.newLenientNetworkSnapshot("code-372", name: "name-711")
        try item.moveTo(Referrals.LenientNetworkSnapshotStatus.resolved)
        #expect(item.status == Referrals.LenientNetworkSnapshotStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newLenientNetworkSnapshot("code-372", name: "name-711")
        item.status = Referrals.LenientNetworkSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.LenientNetworkSnapshotStatus.`open`) }
    }
}
