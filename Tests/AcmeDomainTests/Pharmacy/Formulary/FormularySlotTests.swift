@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularySlotTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newFormularySlot("code-816", title: "title-381")
        #expect(item.status == Pharmacy.FormularySlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newFormularySlot("code-816", title: "title-381")
        try item.moveTo(Pharmacy.FormularySlotStatus.active)
        #expect(item.status == Pharmacy.FormularySlotStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newFormularySlot("code-816", title: "title-381")
        item.status = Pharmacy.FormularySlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularySlotStatus.draft) }
    }
}
