@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientClaimPolicyTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newLenientClaimPolicy("code-42", name: "name-282")
        #expect(item.status == RevenueCycle.LenientClaimPolicyStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newLenientClaimPolicy("code-42", name: "name-282")
        try item.moveTo(RevenueCycle.LenientClaimPolicyStatus.suspended)
        #expect(item.status == RevenueCycle.LenientClaimPolicyStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newLenientClaimPolicy("code-42", name: "name-282")
        item.status = RevenueCycle.LenientClaimPolicyStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientClaimPolicyStatus.draft) }
    }
}
