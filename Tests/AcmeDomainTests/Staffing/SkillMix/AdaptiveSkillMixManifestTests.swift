@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveSkillMixManifestTests {
    @Test func startsInNew() throws {
        let item = Staffing.newAdaptiveSkillMixManifest("code-727", title: "title-991")
        #expect(item.status == Staffing.AdaptiveSkillMixManifestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newAdaptiveSkillMixManifest("code-727", title: "title-991")
        try item.moveTo(Staffing.AdaptiveSkillMixManifestStatus.queued)
        #expect(item.status == Staffing.AdaptiveSkillMixManifestStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newAdaptiveSkillMixManifest("code-727", title: "title-991")
        item.status = Staffing.AdaptiveSkillMixManifestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.AdaptiveSkillMixManifestStatus.new) }
    }
}
