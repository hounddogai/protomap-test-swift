@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyOrderSetThresholdTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newLegacyOrderSetThreshold("code-243", title: "title-306")
        #expect(item.status == ClinicalOps.LegacyOrderSetThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newLegacyOrderSetThreshold("code-243", title: "title-306")
        try item.moveTo(ClinicalOps.LegacyOrderSetThresholdStatus.inReview)
        #expect(item.status == ClinicalOps.LegacyOrderSetThresholdStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newLegacyOrderSetThreshold("code-243", title: "title-306")
        item.status = ClinicalOps.LegacyOrderSetThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.LegacyOrderSetThresholdStatus.`open`) }
    }
}
