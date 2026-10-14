@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixEstimateTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newSkillMixEstimate("code-42", title: "title-923")
        #expect(item.status == Staffing.SkillMixEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newSkillMixEstimate("code-42", title: "title-923")
        try item.moveTo(Staffing.SkillMixEstimateStatus.granted)
        #expect(item.status == Staffing.SkillMixEstimateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newSkillMixEstimate("code-42", title: "title-923")
        item.status = Staffing.SkillMixEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixEstimateStatus.requested) }
    }
}
