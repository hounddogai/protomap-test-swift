@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacySkillMixSlotTests {
    @Test func startsInNew() throws {
        let item = Staffing.newLegacySkillMixSlot("code-50", label: "label-186")
        #expect(item.status == Staffing.LegacySkillMixSlotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Staffing.newLegacySkillMixSlot("code-50", label: "label-186")
        try item.moveTo(Staffing.LegacySkillMixSlotStatus.failed)
        #expect(item.status == Staffing.LegacySkillMixSlotStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newLegacySkillMixSlot("code-50", label: "label-186")
        item.status = Staffing.LegacySkillMixSlotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacySkillMixSlotStatus.new) }
    }
}
