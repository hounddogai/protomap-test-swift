@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAgreementTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newFormularyAgreement("code-474", title: "title-591")
        #expect(item.status == Pharmacy.FormularyAgreementStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newFormularyAgreement("code-474", title: "title-591")
        try item.moveTo(Pharmacy.FormularyAgreementStatus.ready)
        #expect(item.status == Pharmacy.FormularyAgreementStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newFormularyAgreement("code-474", title: "title-591")
        item.status = Pharmacy.FormularyAgreementStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyAgreementStatus.idle) }
    }
}
