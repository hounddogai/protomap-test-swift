@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackStatementNoticeTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newFallbackStatementNotice("code-149", title: "title-422")
        #expect(item.status == RevenueCycle.FallbackStatementNoticeStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = RevenueCycle.newFallbackStatementNotice("code-149", title: "title-422")
        try item.moveTo(RevenueCycle.FallbackStatementNoticeStatus.queued)
        #expect(item.status == RevenueCycle.FallbackStatementNoticeStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newFallbackStatementNotice("code-149", title: "title-422")
        item.status = RevenueCycle.FallbackStatementNoticeStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.FallbackStatementNoticeStatus.new) }
    }
}
