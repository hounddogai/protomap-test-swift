@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolPlanTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newFloatPoolPlan("code-888", title: "title-929")
        #expect(item.status == Staffing.FloatPoolPlanStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newFloatPoolPlan("code-888", title: "title-929")
        try item.moveTo(Staffing.FloatPoolPlanStatus.withdrawn)
        #expect(item.status == Staffing.FloatPoolPlanStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newFloatPoolPlan("code-888", title: "title-929")
        item.status = Staffing.FloatPoolPlanStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FloatPoolPlanStatus.proposed) }
    }
}
