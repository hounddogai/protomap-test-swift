@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultRiskScoreGroupTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newDefaultRiskScoreGroup("code-759", label: "label-796")
        #expect(item.status == CareManagement.DefaultRiskScoreGroupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = CareManagement.newDefaultRiskScoreGroup("code-759", label: "label-796")
        try item.moveTo(CareManagement.DefaultRiskScoreGroupStatus.draining)
        #expect(item.status == CareManagement.DefaultRiskScoreGroupStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newDefaultRiskScoreGroup("code-759", label: "label-796")
        item.status = CareManagement.DefaultRiskScoreGroupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultRiskScoreGroupStatus.idle) }
    }
}
