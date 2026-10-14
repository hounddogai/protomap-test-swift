@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInteractionAgreementTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newSeasonalInteractionAgreement("code-160", label: "label-493")
        #expect(item.status == Pharmacy.SeasonalInteractionAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newSeasonalInteractionAgreement("code-160", label: "label-493")
        try item.moveTo(Pharmacy.SeasonalInteractionAgreementStatus.validated)
        #expect(item.status == Pharmacy.SeasonalInteractionAgreementStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newSeasonalInteractionAgreement("code-160", label: "label-493")
        item.status = Pharmacy.SeasonalInteractionAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SeasonalInteractionAgreementStatus.created) }
    }
}
