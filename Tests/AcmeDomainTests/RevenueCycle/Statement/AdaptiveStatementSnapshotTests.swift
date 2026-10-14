@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementSnapshotTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newAdaptiveStatementSnapshot("code-144", name: "name-289")
        #expect(item.status == RevenueCycle.AdaptiveStatementSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newAdaptiveStatementSnapshot("code-144", name: "name-289")
        try item.moveTo(RevenueCycle.AdaptiveStatementSnapshotStatus.inReview)
        #expect(item.status == RevenueCycle.AdaptiveStatementSnapshotStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newAdaptiveStatementSnapshot("code-144", name: "name-289")
        item.status = RevenueCycle.AdaptiveStatementSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveStatementSnapshotStatus.`open`) }
    }
}
