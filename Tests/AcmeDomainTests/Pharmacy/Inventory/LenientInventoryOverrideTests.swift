@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryOverrideTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newLenientInventoryOverride("code-729", label: "label-227")
        #expect(item.status == Pharmacy.LenientInventoryOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newLenientInventoryOverride("code-729", label: "label-227")
        try item.moveTo(Pharmacy.LenientInventoryOverrideStatus.expired)
        #expect(item.status == Pharmacy.LenientInventoryOverrideStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newLenientInventoryOverride("code-729", label: "label-227")
        item.status = Pharmacy.LenientInventoryOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientInventoryOverrideStatus.requested) }
    }
}
