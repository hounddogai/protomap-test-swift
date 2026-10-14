@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInteractionWindowTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newRegionalInteractionWindow("code-907", title: "title-157")
        #expect(item.status == Pharmacy.RegionalInteractionWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newRegionalInteractionWindow("code-907", title: "title-157")
        try item.moveTo(Pharmacy.RegionalInteractionWindowStatus.pending)
        #expect(item.status == Pharmacy.RegionalInteractionWindowStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newRegionalInteractionWindow("code-907", title: "title-157")
        item.status = Pharmacy.RegionalInteractionWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalInteractionWindowStatus.draft) }
    }
}
