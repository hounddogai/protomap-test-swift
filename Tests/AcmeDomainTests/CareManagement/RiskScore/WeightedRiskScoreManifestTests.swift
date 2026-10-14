@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedRiskScoreManifestTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newWeightedRiskScoreManifest("code-840", label: "label-542")
        #expect(item.status == CareManagement.WeightedRiskScoreManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = CareManagement.newWeightedRiskScoreManifest("code-840", label: "label-542")
        try item.moveTo(CareManagement.WeightedRiskScoreManifestStatus.closed)
        #expect(item.status == CareManagement.WeightedRiskScoreManifestStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newWeightedRiskScoreManifest("code-840", label: "label-542")
        item.status = CareManagement.WeightedRiskScoreManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedRiskScoreManifestStatus.draft) }
    }
}
