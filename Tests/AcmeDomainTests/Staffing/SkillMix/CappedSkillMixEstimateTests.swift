@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixEstimateTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newCappedSkillMixEstimate("code-188", name: "name-604")
        #expect(item.status == Staffing.CappedSkillMixEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Staffing.newCappedSkillMixEstimate("code-188", name: "name-604")
        try item.moveTo(Staffing.CappedSkillMixEstimateStatus.closed)
        #expect(item.status == Staffing.CappedSkillMixEstimateStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newCappedSkillMixEstimate("code-188", name: "name-604")
        item.status = Staffing.CappedSkillMixEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedSkillMixEstimateStatus.draft) }
    }
}
