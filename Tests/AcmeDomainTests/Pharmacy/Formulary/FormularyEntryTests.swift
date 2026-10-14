@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyEntryTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newFormularyEntry("code-791", label: "label-255")
        #expect(item.status == Pharmacy.FormularyEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newFormularyEntry("code-791", label: "label-255")
        try item.moveTo(Pharmacy.FormularyEntryStatus.suspended)
        #expect(item.status == Pharmacy.FormularyEntryStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newFormularyEntry("code-791", label: "label-255")
        item.status = Pharmacy.FormularyEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyEntryStatus.draft) }
    }
}
