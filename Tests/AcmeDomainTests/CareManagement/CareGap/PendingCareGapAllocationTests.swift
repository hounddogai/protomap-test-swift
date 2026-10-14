@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingCareGapAllocationTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newPendingCareGapAllocation("code-160", title: "title-594")
        #expect(item.status == CareManagement.PendingCareGapAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newPendingCareGapAllocation("code-160", title: "title-594")
        try item.moveTo(CareManagement.PendingCareGapAllocationStatus.active)
        #expect(item.status == CareManagement.PendingCareGapAllocationStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newPendingCareGapAllocation("code-160", title: "title-594")
        item.status = CareManagement.PendingCareGapAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.PendingCareGapAllocationStatus.draft) }
    }
}
