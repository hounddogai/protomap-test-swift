@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationSnapshotTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("code-442", title: "title-327")
        #expect(item.status == RevenueCycle.BatchedAuthorizationSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("code-442", title: "title-327")
        try item.moveTo(RevenueCycle.BatchedAuthorizationSnapshotStatus.resolved)
        #expect(item.status == RevenueCycle.BatchedAuthorizationSnapshotStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newBatchedAuthorizationSnapshot("code-442", title: "title-327")
        item.status = RevenueCycle.BatchedAuthorizationSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedAuthorizationSnapshotStatus.`open`) }
    }
}
