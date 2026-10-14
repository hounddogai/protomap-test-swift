@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixVarianceTests {
    @Test func startsInNew() throws {
        let item = Staffing.newSkillMixVariance("code-103", name: "name-588")
        #expect(item.status == Staffing.SkillMixVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newSkillMixVariance("code-103", name: "name-588")
        try item.moveTo(Staffing.SkillMixVarianceStatus.queued)
        #expect(item.status == Staffing.SkillMixVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newSkillMixVariance("code-103", name: "name-588")
        item.status = Staffing.SkillMixVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixVarianceStatus.new) }
    }
}
