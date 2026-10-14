@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftAllocationTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newGlobalShiftAllocation("code-214", title: "title-48")
        #expect(item.status == Staffing.GlobalShiftAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newGlobalShiftAllocation("code-214", title: "title-48")
        try item.moveTo(Staffing.GlobalShiftAllocationStatus.revoked)
        #expect(item.status == Staffing.GlobalShiftAllocationStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newGlobalShiftAllocation("code-214", title: "title-48")
        item.status = Staffing.GlobalShiftAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalShiftAllocationStatus.requested) }
    }
}
