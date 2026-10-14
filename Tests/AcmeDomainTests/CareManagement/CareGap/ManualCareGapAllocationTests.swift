@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapAllocationTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newManualCareGapAllocation("code-931", title: "title-351")
        #expect(item.status == CareManagement.ManualCareGapAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newManualCareGapAllocation("code-931", title: "title-351")
        try item.moveTo(CareManagement.ManualCareGapAllocationStatus.warming)
        #expect(item.status == CareManagement.ManualCareGapAllocationStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newManualCareGapAllocation("code-931", title: "title-351")
        item.status = CareManagement.ManualCareGapAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ManualCareGapAllocationStatus.idle) }
    }
}
