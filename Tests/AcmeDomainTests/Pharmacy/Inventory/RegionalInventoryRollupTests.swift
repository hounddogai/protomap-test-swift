@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInventoryRollupTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRegionalInventoryRollup("code-364", label: "label-587")
        #expect(item.status == Pharmacy.RegionalInventoryRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newRegionalInventoryRollup("code-364", label: "label-587")
        try item.moveTo(Pharmacy.RegionalInventoryRollupStatus.completed)
        #expect(item.status == Pharmacy.RegionalInventoryRollupStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRegionalInventoryRollup("code-364", label: "label-587")
        item.status = Pharmacy.RegionalInventoryRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RegionalInventoryRollupStatus.planned) }
    }
}
