@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementNoticeTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newStatementNotice("code-978", name: "name-780")
        #expect(item.status == RevenueCycle.StatementNoticeStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newStatementNotice("code-978", name: "name-780")
        try item.moveTo(RevenueCycle.StatementNoticeStatus.ready)
        #expect(item.status == RevenueCycle.StatementNoticeStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newStatementNotice("code-978", name: "name-780")
        item.status = RevenueCycle.StatementNoticeStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementNoticeStatus.idle) }
    }
}
