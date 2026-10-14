@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolCycleTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newFloatPoolCycle("code-505", name: "name-408")
        #expect(item.status == Staffing.FloatPoolCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newFloatPoolCycle("code-505", name: "name-408")
        try item.moveTo(Staffing.FloatPoolCycleStatus.validated)
        #expect(item.status == Staffing.FloatPoolCycleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newFloatPoolCycle("code-505", name: "name-408")
        item.status = Staffing.FloatPoolCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolCycleStatus.created) }
    }
}
