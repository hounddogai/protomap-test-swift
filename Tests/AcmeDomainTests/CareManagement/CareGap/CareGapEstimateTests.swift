@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapEstimateTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newCareGapEstimate("code-638", label: "label-464")
        #expect(item.status == CareManagement.CareGapEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newCareGapEstimate("code-638", label: "label-464")
        try item.moveTo(CareManagement.CareGapEstimateStatus.inReview)
        #expect(item.status == CareManagement.CareGapEstimateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newCareGapEstimate("code-638", label: "label-464")
        item.status = CareManagement.CareGapEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapEstimateStatus.`open`) }
    }
}
