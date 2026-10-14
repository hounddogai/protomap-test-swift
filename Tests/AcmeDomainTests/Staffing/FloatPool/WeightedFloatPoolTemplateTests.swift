@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedFloatPoolTemplateTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newWeightedFloatPoolTemplate("code-437", name: "name-519")
        #expect(item.status == Staffing.WeightedFloatPoolTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newWeightedFloatPoolTemplate("code-437", name: "name-519")
        try item.moveTo(Staffing.WeightedFloatPoolTemplateStatus.approved)
        #expect(item.status == Staffing.WeightedFloatPoolTemplateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newWeightedFloatPoolTemplate("code-437", name: "name-519")
        item.status = Staffing.WeightedFloatPoolTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedFloatPoolTemplateStatus.proposed) }
    }
}
