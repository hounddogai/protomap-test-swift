@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBundleTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newInteractionBundle("code-188", title: "title-541")
        #expect(item.status == Pharmacy.InteractionBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newInteractionBundle("code-188", title: "title-541")
        try item.moveTo(Pharmacy.InteractionBundleStatus.completed)
        #expect(item.status == Pharmacy.InteractionBundleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newInteractionBundle("code-188", title: "title-541")
        item.status = Pharmacy.InteractionBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionBundleStatus.planned) }
    }
}
