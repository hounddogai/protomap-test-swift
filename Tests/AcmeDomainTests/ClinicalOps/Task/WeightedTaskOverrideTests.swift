@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedTaskOverrideTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newWeightedTaskOverride("code-254", name: "name-846")
        #expect(item.status == ClinicalOps.WeightedTaskOverrideStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = ClinicalOps.newWeightedTaskOverride("code-254", name: "name-846")
        try item.moveTo(ClinicalOps.WeightedTaskOverrideStatus.retired)
        #expect(item.status == ClinicalOps.WeightedTaskOverrideStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newWeightedTaskOverride("code-254", name: "name-846")
        item.status = ClinicalOps.WeightedTaskOverrideStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedTaskOverrideStatus.created) }
    }
}
