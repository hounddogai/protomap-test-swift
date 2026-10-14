@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionClaimTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newSubstitutionClaim("code-623", label: "label-774")
        #expect(item.status == Pharmacy.SubstitutionClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newSubstitutionClaim("code-623", label: "label-774")
        try item.moveTo(Pharmacy.SubstitutionClaimStatus.scheduled)
        #expect(item.status == Pharmacy.SubstitutionClaimStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newSubstitutionClaim("code-623", label: "label-774")
        item.status = Pharmacy.SubstitutionClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionClaimStatus.planned) }
    }
}
