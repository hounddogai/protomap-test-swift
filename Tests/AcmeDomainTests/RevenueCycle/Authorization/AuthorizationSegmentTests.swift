@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationSegmentTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newAuthorizationSegment("code-220", name: "name-436")
        #expect(item.status == RevenueCycle.AuthorizationSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newAuthorizationSegment("code-220", name: "name-436")
        try item.moveTo(RevenueCycle.AuthorizationSegmentStatus.active)
        #expect(item.status == RevenueCycle.AuthorizationSegmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newAuthorizationSegment("code-220", name: "name-436")
        item.status = RevenueCycle.AuthorizationSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationSegmentStatus.draft) }
    }
}
