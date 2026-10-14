@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementSegmentTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newBatchedStatementSegment("code-521", name: "name-198")
        #expect(item.status == RevenueCycle.BatchedStatementSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newBatchedStatementSegment("code-521", name: "name-198")
        try item.moveTo(RevenueCycle.BatchedStatementSegmentStatus.revoked)
        #expect(item.status == RevenueCycle.BatchedStatementSegmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newBatchedStatementSegment("code-521", name: "name-198")
        item.status = RevenueCycle.BatchedStatementSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedStatementSegmentStatus.requested) }
    }
}
