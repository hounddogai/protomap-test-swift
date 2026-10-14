@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationBatchTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newAuthorizationBatch("code-969", title: "title-123")
        #expect(item.status == RevenueCycle.AuthorizationBatchStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newAuthorizationBatch("code-969", title: "title-123")
        try item.moveTo(RevenueCycle.AuthorizationBatchStatus.pending)
        #expect(item.status == RevenueCycle.AuthorizationBatchStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newAuthorizationBatch("code-969", title: "title-123")
        item.status = RevenueCycle.AuthorizationBatchStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationBatchStatus.draft) }
    }
}
