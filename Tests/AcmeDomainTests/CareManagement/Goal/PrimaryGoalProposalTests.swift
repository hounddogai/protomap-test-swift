@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryGoalProposalTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newPrimaryGoalProposal("code-93", label: "label-701")
        #expect(item.status == CareManagement.PrimaryGoalProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = CareManagement.newPrimaryGoalProposal("code-93", label: "label-701")
        try item.moveTo(CareManagement.PrimaryGoalProposalStatus.expired)
        #expect(item.status == CareManagement.PrimaryGoalProposalStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newPrimaryGoalProposal("code-93", label: "label-701")
        item.status = CareManagement.PrimaryGoalProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryGoalProposalStatus.requested) }
    }
}
