@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixAdjustmentTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newSkillMixAdjustment("code-271", label: "label-693")
        #expect(item.status == Staffing.SkillMixAdjustmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newSkillMixAdjustment("code-271", label: "label-693")
        try item.moveTo(Staffing.SkillMixAdjustmentStatus.granted)
        #expect(item.status == Staffing.SkillMixAdjustmentStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newSkillMixAdjustment("code-271", label: "label-693")
        item.status = Staffing.SkillMixAdjustmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixAdjustmentStatus.requested) }
    }
}
