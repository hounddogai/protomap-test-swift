@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySegmentTests {
    @Test func startsInRequested() throws {
        let item = Referrals.newEligibilitySegment("code-523", title: "title-447")
        #expect(item.status == Referrals.EligibilitySegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Referrals.newEligibilitySegment("code-523", title: "title-447")
        try item.moveTo(Referrals.EligibilitySegmentStatus.granted)
        #expect(item.status == Referrals.EligibilitySegmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Referrals.newEligibilitySegment("code-523", title: "title-447")
        item.status = Referrals.EligibilitySegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.EligibilitySegmentStatus.requested) }
    }
}
