@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosureCycleTests {
    @Test func startsInRequested() throws {
        let item = Consent.newBatchedDisclosureCycle("code-416", name: "name-318")
        #expect(item.status == Consent.BatchedDisclosureCycleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Consent.newBatchedDisclosureCycle("code-416", name: "name-318")
        try item.moveTo(Consent.BatchedDisclosureCycleStatus.revoked)
        #expect(item.status == Consent.BatchedDisclosureCycleStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newBatchedDisclosureCycle("code-416", name: "name-318")
        item.status = Consent.BatchedDisclosureCycleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedDisclosureCycleStatus.requested) }
    }
}
