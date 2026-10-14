@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSkillMixManifestTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSkillMixManifest("code-629", name: "name-458")
        #expect(item.status == Staffing.SkillMixManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newSkillMixManifest("code-629", name: "name-458")
        try item.moveTo(Staffing.SkillMixManifestStatus.pending)
        #expect(item.status == Staffing.SkillMixManifestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSkillMixManifest("code-629", name: "name-458")
        item.status = Staffing.SkillMixManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SkillMixManifestStatus.draft) }
    }
}
