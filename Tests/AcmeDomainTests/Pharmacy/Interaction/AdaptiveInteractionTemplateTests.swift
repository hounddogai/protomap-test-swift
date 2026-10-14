@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInteractionTemplateTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newAdaptiveInteractionTemplate("code-549", label: "label-279")
        #expect(item.status == Pharmacy.AdaptiveInteractionTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newAdaptiveInteractionTemplate("code-549", label: "label-279")
        try item.moveTo(Pharmacy.AdaptiveInteractionTemplateStatus.granted)
        #expect(item.status == Pharmacy.AdaptiveInteractionTemplateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newAdaptiveInteractionTemplate("code-549", label: "label-279")
        item.status = Pharmacy.AdaptiveInteractionTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveInteractionTemplateStatus.requested) }
    }
}
