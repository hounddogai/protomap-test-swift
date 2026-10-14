@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedCareGapClaimTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newCappedCareGapClaim("code-401", label: "label-306")
        #expect(item.status == CareManagement.CappedCareGapClaimStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newCappedCareGapClaim("code-401", label: "label-306")
        try item.moveTo(CareManagement.CappedCareGapClaimStatus.validated)
        #expect(item.status == CareManagement.CappedCareGapClaimStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newCappedCareGapClaim("code-401", label: "label-306")
        item.status = CareManagement.CappedCareGapClaimStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedCareGapClaimStatus.created) }
    }
}
