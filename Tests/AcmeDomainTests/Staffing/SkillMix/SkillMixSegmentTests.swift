@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixSegmentTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newSkillMixSegment("code-584", label: "label-942")
        #expect(item.status == Staffing.SkillMixSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Staffing.newSkillMixSegment("code-584", label: "label-942")
        try item.moveTo(Staffing.SkillMixSegmentStatus.published)
        #expect(item.status == Staffing.SkillMixSegmentStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newSkillMixSegment("code-584", label: "label-942")
        item.status = Staffing.SkillMixSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixSegmentStatus.created) }
    }
}
