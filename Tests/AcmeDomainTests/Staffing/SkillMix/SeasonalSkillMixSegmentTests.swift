@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalSkillMixSegmentTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newSeasonalSkillMixSegment("code-158", name: "name-20")
        #expect(item.status == Staffing.SeasonalSkillMixSegmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newSeasonalSkillMixSegment("code-158", name: "name-20")
        try item.moveTo(Staffing.SeasonalSkillMixSegmentStatus.ready)
        #expect(item.status == Staffing.SeasonalSkillMixSegmentStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newSeasonalSkillMixSegment("code-158", name: "name-20")
        item.status = Staffing.SeasonalSkillMixSegmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalSkillMixSegmentStatus.idle) }
    }
}
