@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedSubstitutionProposalTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newWeightedSubstitutionProposal("code-895", title: "title-940")
        #expect(item.status == Pharmacy.WeightedSubstitutionProposalStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newWeightedSubstitutionProposal("code-895", title: "title-940")
        try item.moveTo(Pharmacy.WeightedSubstitutionProposalStatus.granted)
        #expect(item.status == Pharmacy.WeightedSubstitutionProposalStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newWeightedSubstitutionProposal("code-895", title: "title-940")
        item.status = Pharmacy.WeightedSubstitutionProposalStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedSubstitutionProposalStatus.requested) }
    }
}
