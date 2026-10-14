@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationNoticeTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newAuthorizationNotice("code-313", label: "label-277")
        #expect(item.status == RevenueCycle.AuthorizationNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newAuthorizationNotice("code-313", label: "label-277")
        try item.moveTo(RevenueCycle.AuthorizationNoticeStatus.queued)
        #expect(item.status == RevenueCycle.AuthorizationNoticeStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newAuthorizationNotice("code-313", label: "label-277")
        item.status = RevenueCycle.AuthorizationNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationNoticeStatus.new) }
    }
}
