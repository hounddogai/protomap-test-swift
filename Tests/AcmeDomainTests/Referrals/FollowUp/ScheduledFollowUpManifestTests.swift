@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpManifestTests {
    @Test func startsInCreated() throws {
        let item = Referrals.newScheduledFollowUpManifest("code-550", title: "title-523")
        #expect(item.status == Referrals.ScheduledFollowUpManifestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Referrals.newScheduledFollowUpManifest("code-550", title: "title-523")
        try item.moveTo(Referrals.ScheduledFollowUpManifestStatus.published)
        #expect(item.status == Referrals.ScheduledFollowUpManifestStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Referrals.newScheduledFollowUpManifest("code-550", title: "title-523")
        item.status = Referrals.ScheduledFollowUpManifestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledFollowUpManifestStatus.created) }
    }
}
