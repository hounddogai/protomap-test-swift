@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolAllocationTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newFloatPoolAllocation("code-641", title: "title-367")
        #expect(item.status == Staffing.FloatPoolAllocationStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newFloatPoolAllocation("code-641", title: "title-367")
        try item.moveTo(Staffing.FloatPoolAllocationStatus.warming)
        #expect(item.status == Staffing.FloatPoolAllocationStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newFloatPoolAllocation("code-641", title: "title-367")
        item.status = Staffing.FloatPoolAllocationStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolAllocationStatus.idle) }
    }
}
