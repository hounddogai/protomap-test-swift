@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationBaselineTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newBatchedAuthorizationBaseline("code-856", name: "name-455")
        #expect(item.status == RevenueCycle.BatchedAuthorizationBaselineStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = RevenueCycle.newBatchedAuthorizationBaseline("code-856", name: "name-455")
        try item.moveTo(RevenueCycle.BatchedAuthorizationBaselineStatus.archived)
        #expect(item.status == RevenueCycle.BatchedAuthorizationBaselineStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newBatchedAuthorizationBaseline("code-856", name: "name-455")
        item.status = RevenueCycle.BatchedAuthorizationBaselineStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedAuthorizationBaselineStatus.`open`) }
    }
}
