@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixSlotTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newCappedSkillMixSlot("code-910", title: "title-557")
        #expect(item.status == Staffing.CappedSkillMixSlotStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newCappedSkillMixSlot("code-910", title: "title-557")
        try item.moveTo(Staffing.CappedSkillMixSlotStatus.active)
        #expect(item.status == Staffing.CappedSkillMixSlotStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newCappedSkillMixSlot("code-910", title: "title-557")
        item.status = Staffing.CappedSkillMixSlotStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedSkillMixSlotStatus.draft) }
    }
}
