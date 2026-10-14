@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInventoryPreferenceTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newCappedInventoryPreference("code-873", name: "name-856")
        #expect(item.status == Pharmacy.CappedInventoryPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Pharmacy.newCappedInventoryPreference("code-873", name: "name-856")
        try item.moveTo(Pharmacy.CappedInventoryPreferenceStatus.ready)
        #expect(item.status == Pharmacy.CappedInventoryPreferenceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newCappedInventoryPreference("code-873", name: "name-856")
        item.status = Pharmacy.CappedInventoryPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedInventoryPreferenceStatus.idle) }
    }
}
