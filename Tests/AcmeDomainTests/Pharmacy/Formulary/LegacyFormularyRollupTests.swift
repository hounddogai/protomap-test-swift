@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyFormularyRollupTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newLegacyFormularyRollup("code-934", label: "label-599")
        #expect(item.status == Pharmacy.LegacyFormularyRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Pharmacy.newLegacyFormularyRollup("code-934", label: "label-599")
        try item.moveTo(Pharmacy.LegacyFormularyRollupStatus.failed)
        #expect(item.status == Pharmacy.LegacyFormularyRollupStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newLegacyFormularyRollup("code-934", label: "label-599")
        item.status = Pharmacy.LegacyFormularyRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyFormularyRollupStatus.new) }
    }
}
