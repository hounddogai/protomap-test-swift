@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionProposalTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newSubstitutionProposal("code-73", title: "title-615")
        #expect(item.status == Pharmacy.SubstitutionProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newSubstitutionProposal("code-73", title: "title-615")
        try item.moveTo(Pharmacy.SubstitutionProposalStatus.queued)
        #expect(item.status == Pharmacy.SubstitutionProposalStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newSubstitutionProposal("code-73", title: "title-615")
        item.status = Pharmacy.SubstitutionProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionProposalStatus.new) }
    }
}
