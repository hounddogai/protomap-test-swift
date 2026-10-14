@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newInteractionPreference("code-671", label: "label-168")
        #expect(item.status == Pharmacy.InteractionPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newInteractionPreference("code-671", label: "label-168")
        try item.moveTo(Pharmacy.InteractionPreferenceStatus.inProgress)
        #expect(item.status == Pharmacy.InteractionPreferenceStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newInteractionPreference("code-671", label: "label-168")
        item.status = Pharmacy.InteractionPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionPreferenceStatus.planned) }
    }
}
