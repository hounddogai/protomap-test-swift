@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionProposalTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newBatchedSubstitutionProposal("code-401", name: "name-640")
        #expect(item.status == Pharmacy.BatchedSubstitutionProposalStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Pharmacy.newBatchedSubstitutionProposal("code-401", name: "name-640")
        try item.moveTo(Pharmacy.BatchedSubstitutionProposalStatus.failed)
        #expect(item.status == Pharmacy.BatchedSubstitutionProposalStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newBatchedSubstitutionProposal("code-401", name: "name-640")
        item.status = Pharmacy.BatchedSubstitutionProposalStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.BatchedSubstitutionProposalStatus.new) }
    }
}
