@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveProgramClaimTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newAdaptiveProgramClaim("code-969", title: "title-903")
        #expect(item.status == CareManagement.AdaptiveProgramClaimStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newAdaptiveProgramClaim("code-969", title: "title-903")
        try item.moveTo(CareManagement.AdaptiveProgramClaimStatus.revoked)
        #expect(item.status == CareManagement.AdaptiveProgramClaimStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newAdaptiveProgramClaim("code-969", title: "title-903")
        item.status = CareManagement.AdaptiveProgramClaimStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AdaptiveProgramClaimStatus.requested) }
    }
}
