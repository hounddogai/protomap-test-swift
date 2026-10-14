@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallProposalTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRecallProposal("code-335", label: "label-761")
        #expect(item.status == Pharmacy.RecallProposalStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newRecallProposal("code-335", label: "label-761")
        try item.moveTo(Pharmacy.RecallProposalStatus.scheduled)
        #expect(item.status == Pharmacy.RecallProposalStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRecallProposal("code-335", label: "label-761")
        item.status = Pharmacy.RecallProposalStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallProposalStatus.planned) }
    }
}
