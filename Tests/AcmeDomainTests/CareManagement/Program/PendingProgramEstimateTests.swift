@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingProgramEstimateTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newPendingProgramEstimate("code-196", name: "name-761")
        #expect(item.status == CareManagement.PendingProgramEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newPendingProgramEstimate("code-196", name: "name-761")
        try item.moveTo(CareManagement.PendingProgramEstimateStatus.warming)
        #expect(item.status == CareManagement.PendingProgramEstimateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newPendingProgramEstimate("code-196", name: "name-761")
        item.status = CareManagement.PendingProgramEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingProgramEstimateStatus.idle) }
    }
}
