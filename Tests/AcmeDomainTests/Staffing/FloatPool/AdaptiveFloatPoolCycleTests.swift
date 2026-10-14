@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveFloatPoolCycleTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newAdaptiveFloatPoolCycle("code-996", label: "label-59")
        #expect(item.status == Staffing.AdaptiveFloatPoolCycleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newAdaptiveFloatPoolCycle("code-996", label: "label-59")
        try item.moveTo(Staffing.AdaptiveFloatPoolCycleStatus.rejected)
        #expect(item.status == Staffing.AdaptiveFloatPoolCycleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newAdaptiveFloatPoolCycle("code-996", label: "label-59")
        item.status = Staffing.AdaptiveFloatPoolCycleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveFloatPoolCycleStatus.proposed) }
    }
}
