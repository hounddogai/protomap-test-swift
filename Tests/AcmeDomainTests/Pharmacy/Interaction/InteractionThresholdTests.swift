@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionThresholdTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newInteractionThreshold("code-767", name: "name-876")
        #expect(item.status == Pharmacy.InteractionThresholdStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newInteractionThreshold("code-767", name: "name-876")
        try item.moveTo(Pharmacy.InteractionThresholdStatus.granted)
        #expect(item.status == Pharmacy.InteractionThresholdStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newInteractionThreshold("code-767", name: "name-876")
        item.status = Pharmacy.InteractionThresholdStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionThresholdStatus.requested) }
    }
}
