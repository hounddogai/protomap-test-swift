@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryVarianceTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newInventoryVariance("code-822", title: "title-829")
        #expect(item.status == Pharmacy.InventoryVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newInventoryVariance("code-822", title: "title-829")
        try item.moveTo(Pharmacy.InventoryVarianceStatus.validated)
        #expect(item.status == Pharmacy.InventoryVarianceStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newInventoryVariance("code-822", title: "title-829")
        item.status = Pharmacy.InventoryVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryVarianceStatus.created) }
    }
}
