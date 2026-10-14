@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInventoryBaselineTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newFallbackInventoryBaseline("code-691", name: "name-759")
        #expect(item.status == Pharmacy.FallbackInventoryBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Pharmacy.newFallbackInventoryBaseline("code-691", name: "name-759")
        try item.moveTo(Pharmacy.FallbackInventoryBaselineStatus.granted)
        #expect(item.status == Pharmacy.FallbackInventoryBaselineStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newFallbackInventoryBaseline("code-691", name: "name-759")
        item.status = Pharmacy.FallbackInventoryBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackInventoryBaselineStatus.requested) }
    }
}
