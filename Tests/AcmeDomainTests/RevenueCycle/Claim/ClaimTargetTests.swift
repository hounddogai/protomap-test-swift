@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimTargetTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newClaimTarget("code-408", name: "name-488")
        #expect(item.status == RevenueCycle.ClaimTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newClaimTarget("code-408", name: "name-488")
        try item.moveTo(RevenueCycle.ClaimTargetStatus.validated)
        #expect(item.status == RevenueCycle.ClaimTargetStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newClaimTarget("code-408", name: "name-488")
        item.status = RevenueCycle.ClaimTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimTargetStatus.created) }
    }
}
