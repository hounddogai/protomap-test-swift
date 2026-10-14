@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryCycleTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newInventoryCycle("code-949", title: "title-397")
        #expect(item.status == Pharmacy.InventoryCycleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newInventoryCycle("code-949", title: "title-397")
        try item.moveTo(Pharmacy.InventoryCycleStatus.granted)
        #expect(item.status == Pharmacy.InventoryCycleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newInventoryCycle("code-949", title: "title-397")
        item.status = Pharmacy.InventoryCycleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryCycleStatus.requested) }
    }
}
