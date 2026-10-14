@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixDraftTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newSkillMixDraft("code-288", name: "name-362")
        #expect(item.status == Staffing.SkillMixDraftStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newSkillMixDraft("code-288", name: "name-362")
        try item.moveTo(Staffing.SkillMixDraftStatus.ready)
        #expect(item.status == Staffing.SkillMixDraftStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newSkillMixDraft("code-288", name: "name-362")
        item.status = Staffing.SkillMixDraftStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixDraftStatus.idle) }
    }
}
