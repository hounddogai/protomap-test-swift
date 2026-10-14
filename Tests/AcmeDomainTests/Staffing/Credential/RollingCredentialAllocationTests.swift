@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingCredentialAllocationTests {
    @Test func startsInNew() throws {
        let item = Staffing.newRollingCredentialAllocation("code-748", title: "title-279")
        #expect(item.status == Staffing.RollingCredentialAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newRollingCredentialAllocation("code-748", title: "title-279")
        try item.moveTo(Staffing.RollingCredentialAllocationStatus.running)
        #expect(item.status == Staffing.RollingCredentialAllocationStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newRollingCredentialAllocation("code-748", title: "title-279")
        item.status = Staffing.RollingCredentialAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RollingCredentialAllocationStatus.new) }
    }
}
