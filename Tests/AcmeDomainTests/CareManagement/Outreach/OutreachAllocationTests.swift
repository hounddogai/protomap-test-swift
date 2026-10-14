@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachAllocationTests {
    @Test func startsInNew() throws {
        let item = CareManagement.newOutreachAllocation("code-556", label: "label-124")
        #expect(item.status == CareManagement.OutreachAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = CareManagement.newOutreachAllocation("code-556", label: "label-124")
        try item.moveTo(CareManagement.OutreachAllocationStatus.done)
        #expect(item.status == CareManagement.OutreachAllocationStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = CareManagement.newOutreachAllocation("code-556", label: "label-124")
        item.status = CareManagement.OutreachAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.OutreachAllocationStatus.new) }
    }
}
