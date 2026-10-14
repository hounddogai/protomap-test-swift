@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRoundingEstimateTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newRoundingEstimate("code-902", name: "name-420")
        #expect(item.status == ClinicalOps.RoundingEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newRoundingEstimate("code-902", name: "name-420")
        try item.moveTo(ClinicalOps.RoundingEstimateStatus.inReview)
        #expect(item.status == ClinicalOps.RoundingEstimateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newRoundingEstimate("code-902", name: "name-420")
        item.status = ClinicalOps.RoundingEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.RoundingEstimateStatus.`open`) }
    }
}
