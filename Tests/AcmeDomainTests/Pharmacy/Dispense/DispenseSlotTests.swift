@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseSlotTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newDispenseSlot("code-112", name: "name-452")
        #expect(item.status == Pharmacy.DispenseSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newDispenseSlot("code-112", name: "name-452")
        try item.moveTo(Pharmacy.DispenseSlotStatus.suspended)
        #expect(item.status == Pharmacy.DispenseSlotStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newDispenseSlot("code-112", name: "name-452")
        item.status = Pharmacy.DispenseSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseSlotStatus.draft) }
    }
}
