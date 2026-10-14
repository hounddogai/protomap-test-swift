@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationSegmentTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newLegacyAuthorizationSegment("code-727", title: "title-232")
        #expect(item.status == RevenueCycle.LegacyAuthorizationSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newLegacyAuthorizationSegment("code-727", title: "title-232")
        try item.moveTo(RevenueCycle.LegacyAuthorizationSegmentStatus.granted)
        #expect(item.status == RevenueCycle.LegacyAuthorizationSegmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newLegacyAuthorizationSegment("code-727", title: "title-232")
        item.status = RevenueCycle.LegacyAuthorizationSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyAuthorizationSegmentStatus.requested) }
    }
}
