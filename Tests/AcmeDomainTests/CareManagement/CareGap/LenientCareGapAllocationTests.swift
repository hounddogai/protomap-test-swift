@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapAllocationTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newLenientCareGapAllocation("code-86", title: "title-467")
        #expect(item.status == CareManagement.LenientCareGapAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newLenientCareGapAllocation("code-86", title: "title-467")
        try item.moveTo(CareManagement.LenientCareGapAllocationStatus.warming)
        #expect(item.status == CareManagement.LenientCareGapAllocationStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newLenientCareGapAllocation("code-86", title: "title-467")
        item.status = CareManagement.LenientCareGapAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LenientCareGapAllocationStatus.idle) }
    }
}
