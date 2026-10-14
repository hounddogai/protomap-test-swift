@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalOutreachAllocationTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newRegionalOutreachAllocation("code-467", label: "label-461")
        #expect(item.status == CareManagement.RegionalOutreachAllocationStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = CareManagement.newRegionalOutreachAllocation("code-467", label: "label-461")
        try item.moveTo(CareManagement.RegionalOutreachAllocationStatus.pending)
        #expect(item.status == CareManagement.RegionalOutreachAllocationStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newRegionalOutreachAllocation("code-467", label: "label-461")
        item.status = CareManagement.RegionalOutreachAllocationStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalOutreachAllocationStatus.draft) }
    }
}
