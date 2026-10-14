@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionTemplateTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newInteractionTemplate("code-565", label: "label-20")
        #expect(item.status == Pharmacy.InteractionTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newInteractionTemplate("code-565", label: "label-20")
        try item.moveTo(Pharmacy.InteractionTemplateStatus.pending)
        #expect(item.status == Pharmacy.InteractionTemplateStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newInteractionTemplate("code-565", label: "label-20")
        item.status = Pharmacy.InteractionTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionTemplateStatus.draft) }
    }
}
