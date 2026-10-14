@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyRollupTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newWeightedFormularyRollup("code-1", name: "name-280")
        #expect(item.status == Pharmacy.WeightedFormularyRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newWeightedFormularyRollup("code-1", name: "name-280")
        try item.moveTo(Pharmacy.WeightedFormularyRollupStatus.queued)
        #expect(item.status == Pharmacy.WeightedFormularyRollupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newWeightedFormularyRollup("code-1", name: "name-280")
        item.status = Pharmacy.WeightedFormularyRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedFormularyRollupStatus.new) }
    }
}
