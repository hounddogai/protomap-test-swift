@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingRecallProposalTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRollingRecallProposal("code-146", label: "label-719")
        #expect(item.status == Pharmacy.RollingRecallProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newRollingRecallProposal("code-146", label: "label-719")
        try item.moveTo(Pharmacy.RollingRecallProposalStatus.inReview)
        #expect(item.status == Pharmacy.RollingRecallProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRollingRecallProposal("code-146", label: "label-719")
        item.status = Pharmacy.RollingRecallProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingRecallProposalStatus.`open`) }
    }
}
