@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredRiskScoreClaimTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newTieredRiskScoreClaim("code-870", name: "name-462")
        #expect(item.status == CareManagement.TieredRiskScoreClaimStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newTieredRiskScoreClaim("code-870", name: "name-462")
        try item.moveTo(CareManagement.TieredRiskScoreClaimStatus.granted)
        #expect(item.status == CareManagement.TieredRiskScoreClaimStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newTieredRiskScoreClaim("code-870", name: "name-462")
        item.status = CareManagement.TieredRiskScoreClaimStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredRiskScoreClaimStatus.requested) }
    }
}
