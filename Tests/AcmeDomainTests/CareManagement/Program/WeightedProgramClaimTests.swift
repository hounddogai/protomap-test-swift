@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramClaimTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newWeightedProgramClaim("code-543", label: "label-945")
        #expect(item.status == CareManagement.WeightedProgramClaimStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newWeightedProgramClaim("code-543", label: "label-945")
        try item.moveTo(CareManagement.WeightedProgramClaimStatus.published)
        #expect(item.status == CareManagement.WeightedProgramClaimStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newWeightedProgramClaim("code-543", label: "label-945")
        item.status = CareManagement.WeightedProgramClaimStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedProgramClaimStatus.created) }
    }
}
