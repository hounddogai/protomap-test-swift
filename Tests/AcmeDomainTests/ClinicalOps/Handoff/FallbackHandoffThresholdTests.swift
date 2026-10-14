@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackHandoffThresholdTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newFallbackHandoffThreshold("code-995", title: "title-305")
        #expect(item.status == ClinicalOps.FallbackHandoffThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newFallbackHandoffThreshold("code-995", title: "title-305")
        try item.moveTo(ClinicalOps.FallbackHandoffThresholdStatus.inReview)
        #expect(item.status == ClinicalOps.FallbackHandoffThresholdStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newFallbackHandoffThreshold("code-995", title: "title-305")
        item.status = ClinicalOps.FallbackHandoffThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.FallbackHandoffThresholdStatus.`open`) }
    }
}
