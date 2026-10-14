@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementFallbackDischargePlanProposalTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newFallbackDischargePlanProposal("code-572", name: "name-599")
        #expect(item.status == BedManagement.FallbackDischargePlanProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newFallbackDischargePlanProposal("code-572", name: "name-599")
        try item.moveTo(BedManagement.FallbackDischargePlanProposalStatus.queued)
        #expect(item.status == BedManagement.FallbackDischargePlanProposalStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newFallbackDischargePlanProposal("code-572", name: "name-599")
        item.status = BedManagement.FallbackDischargePlanProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.FallbackDischargePlanProposalStatus.new) }
    }
}
