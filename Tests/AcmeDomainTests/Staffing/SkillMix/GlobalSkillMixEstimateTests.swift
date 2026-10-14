@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalSkillMixEstimateTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newGlobalSkillMixEstimate("code-424", title: "title-858")
        #expect(item.status == Staffing.GlobalSkillMixEstimateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newGlobalSkillMixEstimate("code-424", title: "title-858")
        try item.moveTo(Staffing.GlobalSkillMixEstimateStatus.approved)
        #expect(item.status == Staffing.GlobalSkillMixEstimateStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newGlobalSkillMixEstimate("code-424", title: "title-858")
        item.status = Staffing.GlobalSkillMixEstimateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.GlobalSkillMixEstimateStatus.proposed) }
    }
}
