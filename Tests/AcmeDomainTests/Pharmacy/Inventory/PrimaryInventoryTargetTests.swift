@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInventoryTargetTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newPrimaryInventoryTarget("code-809", name: "name-97")
        #expect(item.status == Pharmacy.PrimaryInventoryTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newPrimaryInventoryTarget("code-809", name: "name-97")
        try item.moveTo(Pharmacy.PrimaryInventoryTargetStatus.validated)
        #expect(item.status == Pharmacy.PrimaryInventoryTargetStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newPrimaryInventoryTarget("code-809", name: "name-97")
        item.status = Pharmacy.PrimaryInventoryTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryInventoryTargetStatus.created) }
    }
}
