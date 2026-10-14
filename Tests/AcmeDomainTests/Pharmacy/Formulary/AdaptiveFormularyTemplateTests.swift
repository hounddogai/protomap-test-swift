@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyTemplateTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newAdaptiveFormularyTemplate("code-608", label: "label-716")
        #expect(item.status == Pharmacy.AdaptiveFormularyTemplateStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newAdaptiveFormularyTemplate("code-608", label: "label-716")
        try item.moveTo(Pharmacy.AdaptiveFormularyTemplateStatus.scheduled)
        #expect(item.status == Pharmacy.AdaptiveFormularyTemplateStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newAdaptiveFormularyTemplate("code-608", label: "label-716")
        item.status = Pharmacy.AdaptiveFormularyTemplateStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveFormularyTemplateStatus.planned) }
    }
}
