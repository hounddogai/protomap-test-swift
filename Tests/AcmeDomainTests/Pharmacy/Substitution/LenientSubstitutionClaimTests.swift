@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionClaimTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newLenientSubstitutionClaim("code-966", name: "name-323")
        #expect(item.status == Pharmacy.LenientSubstitutionClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newLenientSubstitutionClaim("code-966", name: "name-323")
        try item.moveTo(Pharmacy.LenientSubstitutionClaimStatus.scheduled)
        #expect(item.status == Pharmacy.LenientSubstitutionClaimStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newLenientSubstitutionClaim("code-966", name: "name-323")
        item.status = Pharmacy.LenientSubstitutionClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientSubstitutionClaimStatus.planned) }
    }
}
