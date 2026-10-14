@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAdaptiveCareProtocolEstimateTests {
    @Test func startsInOpen() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolEstimate("code-392", name: "name-581")
        #expect(item.status == ClinicalOps.AdaptiveCareProtocolEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolEstimate("code-392", name: "name-581")
        try item.moveTo(ClinicalOps.AdaptiveCareProtocolEstimateStatus.inReview)
        #expect(item.status == ClinicalOps.AdaptiveCareProtocolEstimateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = ClinicalOps.newAdaptiveCareProtocolEstimate("code-392", name: "name-581")
        item.status = ClinicalOps.AdaptiveCareProtocolEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.AdaptiveCareProtocolEstimateStatus.`open`) }
    }
}
