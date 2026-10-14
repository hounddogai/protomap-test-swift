@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanProposalTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newPrimaryDischargePlanProposal("code-845", name: "name-549")
        #expect(item.status == BedManagement.PrimaryDischargePlanProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newPrimaryDischargePlanProposal("code-845", name: "name-549")
        try item.moveTo(BedManagement.PrimaryDischargePlanProposalStatus.queued)
        #expect(item.status == BedManagement.PrimaryDischargePlanProposalStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newPrimaryDischargePlanProposal("code-845", name: "name-549")
        item.status = BedManagement.PrimaryDischargePlanProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryDischargePlanProposalStatus.new) }
    }
}
