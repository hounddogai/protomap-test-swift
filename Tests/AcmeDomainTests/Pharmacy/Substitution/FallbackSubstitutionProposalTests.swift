@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackSubstitutionProposalTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFallbackSubstitutionProposal("code-692", label: "label-158")
        #expect(item.status == Pharmacy.FallbackSubstitutionProposalStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newFallbackSubstitutionProposal("code-692", label: "label-158")
        try item.moveTo(Pharmacy.FallbackSubstitutionProposalStatus.approved)
        #expect(item.status == Pharmacy.FallbackSubstitutionProposalStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFallbackSubstitutionProposal("code-692", label: "label-158")
        item.status = Pharmacy.FallbackSubstitutionProposalStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackSubstitutionProposalStatus.proposed) }
    }
}
