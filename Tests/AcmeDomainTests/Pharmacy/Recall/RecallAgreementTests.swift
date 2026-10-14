@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAgreementTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newRecallAgreement("code-928", name: "name-383")
        #expect(item.status == Pharmacy.RecallAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newRecallAgreement("code-928", name: "name-383")
        try item.moveTo(Pharmacy.RecallAgreementStatus.validated)
        #expect(item.status == Pharmacy.RecallAgreementStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newRecallAgreement("code-928", name: "name-383")
        item.status = Pharmacy.RecallAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallAgreementStatus.created) }
    }
}
