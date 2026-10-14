@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedInventoryCycleTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newCappedInventoryCycle("code-491", name: "name-91")
        #expect(item.status == Pharmacy.CappedInventoryCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newCappedInventoryCycle("code-491", name: "name-91")
        try item.moveTo(Pharmacy.CappedInventoryCycleStatus.validated)
        #expect(item.status == Pharmacy.CappedInventoryCycleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newCappedInventoryCycle("code-491", name: "name-91")
        item.status = Pharmacy.CappedInventoryCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.CappedInventoryCycleStatus.created) }
    }
}
