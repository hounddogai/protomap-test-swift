@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionWindowTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInteractionWindow("code-889", title: "title-587")
        #expect(item.status == Pharmacy.InteractionWindowStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newInteractionWindow("code-889", title: "title-587")
        try item.moveTo(Pharmacy.InteractionWindowStatus.queued)
        #expect(item.status == Pharmacy.InteractionWindowStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInteractionWindow("code-889", title: "title-587")
        item.status = Pharmacy.InteractionWindowStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionWindowStatus.new) }
    }
}
