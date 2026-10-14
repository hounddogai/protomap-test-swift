@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSegmentTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newStatementSegment("code-918", title: "title-455")
        #expect(item.status == RevenueCycle.StatementSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newStatementSegment("code-918", title: "title-455")
        try item.moveTo(RevenueCycle.StatementSegmentStatus.ready)
        #expect(item.status == RevenueCycle.StatementSegmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newStatementSegment("code-918", title: "title-455")
        item.status = RevenueCycle.StatementSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.StatementSegmentStatus.idle) }
    }
}
