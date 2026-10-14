@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialPolicyTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDenialPolicy("code-39", name: "name-25")
        #expect(item.status == RevenueCycle.DenialPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newDenialPolicy("code-39", name: "name-25")
        try item.moveTo(RevenueCycle.DenialPolicyStatus.approved)
        #expect(item.status == RevenueCycle.DenialPolicyStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDenialPolicy("code-39", name: "name-25")
        item.status = RevenueCycle.DenialPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialPolicyStatus.proposed) }
    }
}
