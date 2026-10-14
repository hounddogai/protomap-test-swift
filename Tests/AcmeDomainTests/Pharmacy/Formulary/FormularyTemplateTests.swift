@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyTemplateTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFormularyTemplate("code-800", title: "title-554")
        #expect(item.status == Pharmacy.FormularyTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Pharmacy.newFormularyTemplate("code-800", title: "title-554")
        try item.moveTo(Pharmacy.FormularyTemplateStatus.withdrawn)
        #expect(item.status == Pharmacy.FormularyTemplateStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFormularyTemplate("code-800", title: "title-554")
        item.status = Pharmacy.FormularyTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyTemplateStatus.proposed) }
    }
}
