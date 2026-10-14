@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpDigestTests {
    @Test func startsInNew() throws {
        let item = Referrals.newScheduledFollowUpDigest("code-713", label: "label-898")
        #expect(item.status == Referrals.ScheduledFollowUpDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Referrals.newScheduledFollowUpDigest("code-713", label: "label-898")
        try item.moveTo(Referrals.ScheduledFollowUpDigestStatus.failed)
        #expect(item.status == Referrals.ScheduledFollowUpDigestStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newScheduledFollowUpDigest("code-713", label: "label-898")
        item.status = Referrals.ScheduledFollowUpDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.ScheduledFollowUpDigestStatus.new) }
    }
}
