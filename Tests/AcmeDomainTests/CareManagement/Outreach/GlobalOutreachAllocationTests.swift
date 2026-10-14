@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalOutreachAllocationTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newGlobalOutreachAllocation("code-308", label: "label-705")
        #expect(item.status == CareManagement.GlobalOutreachAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = CareManagement.newGlobalOutreachAllocation("code-308", label: "label-705")
        try item.moveTo(CareManagement.GlobalOutreachAllocationStatus.ready)
        #expect(item.status == CareManagement.GlobalOutreachAllocationStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newGlobalOutreachAllocation("code-308", label: "label-705")
        item.status = CareManagement.GlobalOutreachAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalOutreachAllocationStatus.idle) }
    }
}
