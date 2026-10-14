@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeProposalTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newChargeProposal("code-170", name: "name-891")
        #expect(item.status == RevenueCycle.ChargeProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = RevenueCycle.newChargeProposal("code-170", name: "name-891")
        try item.moveTo(RevenueCycle.ChargeProposalStatus.revoked)
        #expect(item.status == RevenueCycle.ChargeProposalStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newChargeProposal("code-170", name: "name-891")
        item.status = RevenueCycle.ChargeProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeProposalStatus.requested) }
    }
}
