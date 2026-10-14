@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictClosureSegmentTests {
    @Test func startsInNew() throws {
        let item = Referrals.newStrictClosureSegment("code-260", name: "name-429")
        #expect(item.status == Referrals.StrictClosureSegmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Referrals.newStrictClosureSegment("code-260", name: "name-429")
        try item.moveTo(Referrals.StrictClosureSegmentStatus.running)
        #expect(item.status == Referrals.StrictClosureSegmentStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Referrals.newStrictClosureSegment("code-260", name: "name-429")
        item.status = Referrals.StrictClosureSegmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Referrals.StrictClosureSegmentStatus.new) }
    }
}
