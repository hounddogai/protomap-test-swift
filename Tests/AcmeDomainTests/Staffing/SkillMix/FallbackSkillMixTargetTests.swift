@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixTargetTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newFallbackSkillMixTarget("code-872", title: "title-891")
        #expect(item.status == Staffing.FallbackSkillMixTargetStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newFallbackSkillMixTarget("code-872", title: "title-891")
        try item.moveTo(Staffing.FallbackSkillMixTargetStatus.rejected)
        #expect(item.status == Staffing.FallbackSkillMixTargetStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newFallbackSkillMixTarget("code-872", title: "title-891")
        item.status = Staffing.FallbackSkillMixTargetStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.FallbackSkillMixTargetStatus.proposed) }
    }
}
