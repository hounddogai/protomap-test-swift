@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacySkillMixBundleTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newLegacySkillMixBundle("code-380", label: "label-25")
        #expect(item.status == Staffing.LegacySkillMixBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Staffing.newLegacySkillMixBundle("code-380", label: "label-25")
        try item.moveTo(Staffing.LegacySkillMixBundleStatus.draining)
        #expect(item.status == Staffing.LegacySkillMixBundleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newLegacySkillMixBundle("code-380", label: "label-25")
        item.status = Staffing.LegacySkillMixBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.LegacySkillMixBundleStatus.idle) }
    }
}
