@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictSubstitutionProposalTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newStrictSubstitutionProposal("code-368", name: "name-711")
        #expect(item.status == Pharmacy.StrictSubstitutionProposalStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Pharmacy.newStrictSubstitutionProposal("code-368", name: "name-711")
        try item.moveTo(Pharmacy.StrictSubstitutionProposalStatus.inReview)
        #expect(item.status == Pharmacy.StrictSubstitutionProposalStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newStrictSubstitutionProposal("code-368", name: "name-711")
        item.status = Pharmacy.StrictSubstitutionProposalStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictSubstitutionProposalStatus.`open`) }
    }
}
