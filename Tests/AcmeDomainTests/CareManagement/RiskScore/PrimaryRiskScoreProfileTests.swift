@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryRiskScoreProfileTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newPrimaryRiskScoreProfile("code-50", title: "title-95")
        #expect(item.status == CareManagement.PrimaryRiskScoreProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newPrimaryRiskScoreProfile("code-50", title: "title-95")
        try item.moveTo(CareManagement.PrimaryRiskScoreProfileStatus.ready)
        #expect(item.status == CareManagement.PrimaryRiskScoreProfileStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newPrimaryRiskScoreProfile("code-50", title: "title-95")
        item.status = CareManagement.PrimaryRiskScoreProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PrimaryRiskScoreProfileStatus.idle) }
    }
}
