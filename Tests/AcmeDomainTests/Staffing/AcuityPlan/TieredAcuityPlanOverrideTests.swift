@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredAcuityPlanOverrideTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newTieredAcuityPlanOverride("code-144", name: "name-307")
        #expect(item.status == Staffing.TieredAcuityPlanOverrideStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Staffing.newTieredAcuityPlanOverride("code-144", name: "name-307")
        try item.moveTo(Staffing.TieredAcuityPlanOverrideStatus.withdrawn)
        #expect(item.status == Staffing.TieredAcuityPlanOverrideStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newTieredAcuityPlanOverride("code-144", name: "name-307")
        item.status = Staffing.TieredAcuityPlanOverrideStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.TieredAcuityPlanOverrideStatus.proposed) }
    }
}
