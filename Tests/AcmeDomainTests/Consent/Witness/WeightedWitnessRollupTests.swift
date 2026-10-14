@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedWitnessRollupTests {
    @Test func startsInProposed() throws {
        let item = Consent.newWeightedWitnessRollup("code-211", label: "label-1")
        #expect(item.status == Consent.WeightedWitnessRollupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newWeightedWitnessRollup("code-211", label: "label-1")
        try item.moveTo(Consent.WeightedWitnessRollupStatus.approved)
        #expect(item.status == Consent.WeightedWitnessRollupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newWeightedWitnessRollup("code-211", label: "label-1")
        item.status = Consent.WeightedWitnessRollupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedWitnessRollupStatus.proposed) }
    }
}
