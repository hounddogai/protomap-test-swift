@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimAgreementTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newBatchedClaimAgreement("code-919", label: "label-994")
        #expect(item.status == RevenueCycle.BatchedClaimAgreementStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newBatchedClaimAgreement("code-919", label: "label-994")
        try item.moveTo(RevenueCycle.BatchedClaimAgreementStatus.approved)
        #expect(item.status == RevenueCycle.BatchedClaimAgreementStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newBatchedClaimAgreement("code-919", label: "label-994")
        item.status = RevenueCycle.BatchedClaimAgreementStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.BatchedClaimAgreementStatus.proposed) }
    }
}
