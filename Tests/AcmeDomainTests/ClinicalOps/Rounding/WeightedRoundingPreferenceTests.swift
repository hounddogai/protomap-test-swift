@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedRoundingPreferenceTests {
    @Test func startsInProposed() throws {
        let item = ClinicalOps.newWeightedRoundingPreference("code-818", label: "label-59")
        #expect(item.status == ClinicalOps.WeightedRoundingPreferenceStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = ClinicalOps.newWeightedRoundingPreference("code-818", label: "label-59")
        try item.moveTo(ClinicalOps.WeightedRoundingPreferenceStatus.withdrawn)
        #expect(item.status == ClinicalOps.WeightedRoundingPreferenceStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = ClinicalOps.newWeightedRoundingPreference("code-818", label: "label-59")
        item.status = ClinicalOps.WeightedRoundingPreferenceStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedRoundingPreferenceStatus.proposed) }
    }
}
