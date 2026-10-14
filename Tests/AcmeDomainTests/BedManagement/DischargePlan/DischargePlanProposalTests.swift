@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanProposalTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newDischargePlanProposal("code-921", label: "label-492")
        #expect(item.status == BedManagement.DischargePlanProposalStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newDischargePlanProposal("code-921", label: "label-492")
        try item.moveTo(BedManagement.DischargePlanProposalStatus.active)
        #expect(item.status == BedManagement.DischargePlanProposalStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newDischargePlanProposal("code-921", label: "label-492")
        item.status = BedManagement.DischargePlanProposalStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanProposalStatus.draft) }
    }
}
