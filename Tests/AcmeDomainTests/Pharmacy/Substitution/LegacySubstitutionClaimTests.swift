@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacySubstitutionClaimTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newLegacySubstitutionClaim("code-189", title: "title-177")
        #expect(item.status == Pharmacy.LegacySubstitutionClaimStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newLegacySubstitutionClaim("code-189", title: "title-177")
        try item.moveTo(Pharmacy.LegacySubstitutionClaimStatus.inProgress)
        #expect(item.status == Pharmacy.LegacySubstitutionClaimStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newLegacySubstitutionClaim("code-189", title: "title-177")
        item.status = Pharmacy.LegacySubstitutionClaimStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacySubstitutionClaimStatus.planned) }
    }
}
