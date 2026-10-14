@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedAlertOverrideTests {
    @Test func startsInCreated() throws {
        let item = ClinicalOps.newWeightedAlertOverride("code-443", name: "name-360")
        #expect(item.status == ClinicalOps.WeightedAlertOverrideStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = ClinicalOps.newWeightedAlertOverride("code-443", name: "name-360")
        try item.moveTo(ClinicalOps.WeightedAlertOverrideStatus.published)
        #expect(item.status == ClinicalOps.WeightedAlertOverrideStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = ClinicalOps.newWeightedAlertOverride("code-443", name: "name-360")
        item.status = ClinicalOps.WeightedAlertOverrideStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedAlertOverrideStatus.created) }
    }
}
