@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalFormularyPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newGlobalFormularyPreference("code-383", label: "label-533")
        #expect(item.status == Pharmacy.GlobalFormularyPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newGlobalFormularyPreference("code-383", label: "label-533")
        try item.moveTo(Pharmacy.GlobalFormularyPreferenceStatus.completed)
        #expect(item.status == Pharmacy.GlobalFormularyPreferenceStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newGlobalFormularyPreference("code-383", label: "label-533")
        item.status = Pharmacy.GlobalFormularyPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalFormularyPreferenceStatus.planned) }
    }
}
