@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureBundleTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newSeasonalClosureBundle("code-886", label: "label-846")
        #expect(item.status == Referrals.SeasonalClosureBundleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Referrals.newSeasonalClosureBundle("code-886", label: "label-846")
        try item.moveTo(Referrals.SeasonalClosureBundleStatus.validated)
        #expect(item.status == Referrals.SeasonalClosureBundleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newSeasonalClosureBundle("code-886", label: "label-846")
        item.status = Referrals.SeasonalClosureBundleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.SeasonalClosureBundleStatus.created) }
    }
}
