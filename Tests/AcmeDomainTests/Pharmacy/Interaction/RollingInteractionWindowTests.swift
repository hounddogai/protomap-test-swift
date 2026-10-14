@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInteractionWindowTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newRollingInteractionWindow("code-629", title: "title-185")
        #expect(item.status == Pharmacy.RollingInteractionWindowStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newRollingInteractionWindow("code-629", title: "title-185")
        try item.moveTo(Pharmacy.RollingInteractionWindowStatus.suspended)
        #expect(item.status == Pharmacy.RollingInteractionWindowStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newRollingInteractionWindow("code-629", title: "title-185")
        item.status = Pharmacy.RollingInteractionWindowStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingInteractionWindowStatus.draft) }
    }
}
