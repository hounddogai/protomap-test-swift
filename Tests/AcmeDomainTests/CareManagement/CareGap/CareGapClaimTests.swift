@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapClaimTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newCareGapClaim("code-364", name: "name-651")
        #expect(item.status == CareManagement.CareGapClaimStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = CareManagement.newCareGapClaim("code-364", name: "name-651")
        try item.moveTo(CareManagement.CareGapClaimStatus.validated)
        #expect(item.status == CareManagement.CareGapClaimStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newCareGapClaim("code-364", name: "name-651")
        item.status = CareManagement.CareGapClaimStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapClaimStatus.created) }
    }
}
