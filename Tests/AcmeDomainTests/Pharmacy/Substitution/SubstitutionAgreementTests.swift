@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionAgreementTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newSubstitutionAgreement("code-785", name: "name-300")
        #expect(item.status == Pharmacy.SubstitutionAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newSubstitutionAgreement("code-785", name: "name-300")
        try item.moveTo(Pharmacy.SubstitutionAgreementStatus.revoked)
        #expect(item.status == Pharmacy.SubstitutionAgreementStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newSubstitutionAgreement("code-785", name: "name-300")
        item.status = Pharmacy.SubstitutionAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.SubstitutionAgreementStatus.requested) }
    }
}
