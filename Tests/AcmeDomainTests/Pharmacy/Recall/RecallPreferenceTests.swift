@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallPreferenceTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newRecallPreference("code-813", label: "label-409")
        #expect(item.status == Pharmacy.RecallPreferenceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newRecallPreference("code-813", label: "label-409")
        try item.moveTo(Pharmacy.RecallPreferenceStatus.suspended)
        #expect(item.status == Pharmacy.RecallPreferenceStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newRecallPreference("code-813", label: "label-409")
        item.status = Pharmacy.RecallPreferenceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallPreferenceStatus.draft) }
    }
}
