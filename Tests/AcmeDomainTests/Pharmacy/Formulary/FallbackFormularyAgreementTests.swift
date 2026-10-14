@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackFormularyAgreementTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newFallbackFormularyAgreement("code-953", label: "label-624")
        #expect(item.status == Pharmacy.FallbackFormularyAgreementStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newFallbackFormularyAgreement("code-953", label: "label-624")
        try item.moveTo(Pharmacy.FallbackFormularyAgreementStatus.scheduled)
        #expect(item.status == Pharmacy.FallbackFormularyAgreementStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newFallbackFormularyAgreement("code-953", label: "label-624")
        item.status = Pharmacy.FallbackFormularyAgreementStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackFormularyAgreementStatus.planned) }
    }
}
