@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCappedRiskScoreClaimTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newCappedRiskScoreClaim("code-153", title: "title-93")
        #expect(item.status == CareManagement.CappedRiskScoreClaimStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newCappedRiskScoreClaim("code-153", title: "title-93")
        try item.moveTo(CareManagement.CappedRiskScoreClaimStatus.warming)
        #expect(item.status == CareManagement.CappedRiskScoreClaimStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newCappedRiskScoreClaim("code-153", title: "title-93")
        item.status = CareManagement.CappedRiskScoreClaimStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CappedRiskScoreClaimStatus.idle) }
    }
}
