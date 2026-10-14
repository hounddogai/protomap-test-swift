@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixSlotTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newSkillMixSlot("code-313", title: "title-241")
        #expect(item.status == Staffing.SkillMixSlotStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Staffing.newSkillMixSlot("code-313", title: "title-241")
        try item.moveTo(Staffing.SkillMixSlotStatus.warming)
        #expect(item.status == Staffing.SkillMixSlotStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newSkillMixSlot("code-313", title: "title-241")
        item.status = Staffing.SkillMixSlotStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixSlotStatus.idle) }
    }
}
