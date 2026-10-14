@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledStatementNoticeTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newScheduledStatementNotice("code-74", name: "name-308")
        #expect(item.status == RevenueCycle.ScheduledStatementNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newScheduledStatementNotice("code-74", name: "name-308")
        try item.moveTo(RevenueCycle.ScheduledStatementNoticeStatus.pending)
        #expect(item.status == RevenueCycle.ScheduledStatementNoticeStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newScheduledStatementNotice("code-74", name: "name-308")
        item.status = RevenueCycle.ScheduledStatementNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledStatementNoticeStatus.draft) }
    }
}
