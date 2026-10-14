@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationProposalTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newAuthorizationProposal("code-227", label: "label-799")
        #expect(item.status == RevenueCycle.AuthorizationProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newAuthorizationProposal("code-227", label: "label-799")
        try item.moveTo(RevenueCycle.AuthorizationProposalStatus.approved)
        #expect(item.status == RevenueCycle.AuthorizationProposalStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newAuthorizationProposal("code-227", label: "label-799")
        item.status = RevenueCycle.AuthorizationProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationProposalStatus.proposed) }
    }
}
