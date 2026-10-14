@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalNetworkGroupTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newSeasonalNetworkGroup("code-784", title: "title-245")
        #expect(item.status == Referrals.SeasonalNetworkGroupStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newSeasonalNetworkGroup("code-784", title: "title-245")
        try item.moveTo(Referrals.SeasonalNetworkGroupStatus.validated)
        #expect(item.status == Referrals.SeasonalNetworkGroupStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newSeasonalNetworkGroup("code-784", title: "title-245")
        item.status = Referrals.SeasonalNetworkGroupStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalNetworkGroupStatus.created) }
    }
}
