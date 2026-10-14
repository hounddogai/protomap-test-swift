@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedSkillMixManifestTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newCappedSkillMixManifest("code-280", label: "label-704")
        #expect(item.status == Staffing.CappedSkillMixManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newCappedSkillMixManifest("code-280", label: "label-704")
        try item.moveTo(Staffing.CappedSkillMixManifestStatus.active)
        #expect(item.status == Staffing.CappedSkillMixManifestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newCappedSkillMixManifest("code-280", label: "label-704")
        item.status = Staffing.CappedSkillMixManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CappedSkillMixManifestStatus.draft) }
    }
}
