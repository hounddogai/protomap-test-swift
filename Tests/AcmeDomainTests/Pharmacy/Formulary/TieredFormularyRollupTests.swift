@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredFormularyRollupTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newTieredFormularyRollup("code-141", name: "name-424")
        #expect(item.status == Pharmacy.TieredFormularyRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newTieredFormularyRollup("code-141", name: "name-424")
        try item.moveTo(Pharmacy.TieredFormularyRollupStatus.completed)
        #expect(item.status == Pharmacy.TieredFormularyRollupStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newTieredFormularyRollup("code-141", name: "name-424")
        item.status = Pharmacy.TieredFormularyRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.TieredFormularyRollupStatus.planned) }
    }
}
