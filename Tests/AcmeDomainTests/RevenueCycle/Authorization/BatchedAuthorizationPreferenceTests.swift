@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationPreferenceTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newBatchedAuthorizationPreference("code-601", title: "title-932")
        #expect(item.status == RevenueCycle.BatchedAuthorizationPreferenceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newBatchedAuthorizationPreference("code-601", title: "title-932")
        try item.moveTo(RevenueCycle.BatchedAuthorizationPreferenceStatus.done)
        #expect(item.status == RevenueCycle.BatchedAuthorizationPreferenceStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newBatchedAuthorizationPreference("code-601", title: "title-932")
        item.status = RevenueCycle.BatchedAuthorizationPreferenceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedAuthorizationPreferenceStatus.new) }
    }
}
