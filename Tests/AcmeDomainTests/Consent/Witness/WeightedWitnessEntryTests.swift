@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedWitnessEntryTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newWeightedWitnessEntry("code-964", name: "name-182")
        #expect(item.status == Consent.WeightedWitnessEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newWeightedWitnessEntry("code-964", name: "name-182")
        try item.moveTo(Consent.WeightedWitnessEntryStatus.completed)
        #expect(item.status == Consent.WeightedWitnessEntryStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newWeightedWitnessEntry("code-964", name: "name-182")
        item.status = Consent.WeightedWitnessEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedWitnessEntryStatus.planned) }
    }
}
