@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallCycleTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newWeightedRecallCycle("code-7", name: "name-518")
        #expect(item.status == Pharmacy.WeightedRecallCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newWeightedRecallCycle("code-7", name: "name-518")
        try item.moveTo(Pharmacy.WeightedRecallCycleStatus.suspended)
        #expect(item.status == Pharmacy.WeightedRecallCycleStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newWeightedRecallCycle("code-7", name: "name-518")
        item.status = Pharmacy.WeightedRecallCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedRecallCycleStatus.draft) }
    }
}
