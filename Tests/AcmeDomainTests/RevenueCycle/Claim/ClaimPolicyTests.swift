@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimPolicyTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newClaimPolicy("code-361", name: "name-840")
        #expect(item.status == RevenueCycle.ClaimPolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newClaimPolicy("code-361", name: "name-840")
        try item.moveTo(RevenueCycle.ClaimPolicyStatus.resolved)
        #expect(item.status == RevenueCycle.ClaimPolicyStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newClaimPolicy("code-361", name: "name-840")
        item.status = RevenueCycle.ClaimPolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimPolicyStatus.`open`) }
    }
}
