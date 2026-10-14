@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapClaimTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newWeightedCareGapClaim("code-499", label: "label-456")
        #expect(item.status == CareManagement.WeightedCareGapClaimStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newWeightedCareGapClaim("code-499", label: "label-456")
        try item.moveTo(CareManagement.WeightedCareGapClaimStatus.validated)
        #expect(item.status == CareManagement.WeightedCareGapClaimStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newWeightedCareGapClaim("code-499", label: "label-456")
        item.status = CareManagement.WeightedCareGapClaimStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.WeightedCareGapClaimStatus.created) }
    }
}
