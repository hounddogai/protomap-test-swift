@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationRequestTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newBatchedAuthorizationRequest("code-395", label: "label-742")
        #expect(item.status == RevenueCycle.BatchedAuthorizationRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newBatchedAuthorizationRequest("code-395", label: "label-742")
        try item.moveTo(RevenueCycle.BatchedAuthorizationRequestStatus.active)
        #expect(item.status == RevenueCycle.BatchedAuthorizationRequestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newBatchedAuthorizationRequest("code-395", label: "label-742")
        item.status = RevenueCycle.BatchedAuthorizationRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedAuthorizationRequestStatus.draft) }
    }
}
