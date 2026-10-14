@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAllocationTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newDischargePlanAllocation("code-47", title: "title-883")
        #expect(item.status == BedManagement.DischargePlanAllocationStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newDischargePlanAllocation("code-47", title: "title-883")
        try item.moveTo(BedManagement.DischargePlanAllocationStatus.running)
        #expect(item.status == BedManagement.DischargePlanAllocationStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newDischargePlanAllocation("code-47", title: "title-883")
        item.status = BedManagement.DischargePlanAllocationStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanAllocationStatus.new) }
    }
}
