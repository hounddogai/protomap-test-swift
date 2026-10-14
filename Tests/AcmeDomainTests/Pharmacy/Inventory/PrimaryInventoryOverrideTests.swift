@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryOverrideTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newPrimaryInventoryOverride("code-786", title: "title-999")
        #expect(item.status == Pharmacy.PrimaryInventoryOverrideStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newPrimaryInventoryOverride("code-786", title: "title-999")
        try item.moveTo(Pharmacy.PrimaryInventoryOverrideStatus.validated)
        #expect(item.status == Pharmacy.PrimaryInventoryOverrideStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newPrimaryInventoryOverride("code-786", title: "title-999")
        item.status = Pharmacy.PrimaryInventoryOverrideStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryInventoryOverrideStatus.created) }
    }
}
