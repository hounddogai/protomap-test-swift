@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpManifestTests {
    @Test func startsInPlanned() throws {
        let item = Referrals.newWeightedFollowUpManifest("code-762", title: "title-198")
        #expect(item.status == Referrals.WeightedFollowUpManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Referrals.newWeightedFollowUpManifest("code-762", title: "title-198")
        try item.moveTo(Referrals.WeightedFollowUpManifestStatus.completed)
        #expect(item.status == Referrals.WeightedFollowUpManifestStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Referrals.newWeightedFollowUpManifest("code-762", title: "title-198")
        item.status = Referrals.WeightedFollowUpManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.WeightedFollowUpManifestStatus.planned) }
    }
}
