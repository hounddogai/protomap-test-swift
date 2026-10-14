@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixThresholdTests {
    @Test func startsInNew() throws {
        let item = Staffing.newSkillMixThreshold("code-586", title: "title-115")
        #expect(item.status == Staffing.SkillMixThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newSkillMixThreshold("code-586", title: "title-115")
        try item.moveTo(Staffing.SkillMixThresholdStatus.running)
        #expect(item.status == Staffing.SkillMixThresholdStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newSkillMixThreshold("code-586", title: "title-115")
        item.status = Staffing.SkillMixThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixThresholdStatus.new) }
    }
}
