@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsWeightedHandoffManifestTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newWeightedHandoffManifest("code-873", title: "title-264")
        #expect(item.status == ClinicalOps.WeightedHandoffManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = ClinicalOps.newWeightedHandoffManifest("code-873", title: "title-264")
        try item.moveTo(ClinicalOps.WeightedHandoffManifestStatus.reopened)
        #expect(item.status == ClinicalOps.WeightedHandoffManifestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newWeightedHandoffManifest("code-873", title: "title-264")
        item.status = ClinicalOps.WeightedHandoffManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.WeightedHandoffManifestStatus.`open`) }
    }
}
