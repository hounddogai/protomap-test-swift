@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalInventoryCycleTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newGlobalInventoryCycle("code-77", name: "name-372")
        #expect(item.status == Pharmacy.GlobalInventoryCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newGlobalInventoryCycle("code-77", name: "name-372")
        try item.moveTo(Pharmacy.GlobalInventoryCycleStatus.pending)
        #expect(item.status == Pharmacy.GlobalInventoryCycleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newGlobalInventoryCycle("code-77", name: "name-372")
        item.status = Pharmacy.GlobalInventoryCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalInventoryCycleStatus.draft) }
    }
}
