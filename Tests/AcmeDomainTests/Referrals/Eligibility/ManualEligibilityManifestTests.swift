@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualEligibilityManifestTests {
    @Test func startsInOpen() throws {
        let item = Referrals.newManualEligibilityManifest("code-134", title: "title-590")
        #expect(item.status == Referrals.ManualEligibilityManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Referrals.newManualEligibilityManifest("code-134", title: "title-590")
        try item.moveTo(Referrals.ManualEligibilityManifestStatus.inReview)
        #expect(item.status == Referrals.ManualEligibilityManifestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Referrals.newManualEligibilityManifest("code-134", title: "title-590")
        item.status = Referrals.ManualEligibilityManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ManualEligibilityManifestStatus.`open`) }
    }
}
