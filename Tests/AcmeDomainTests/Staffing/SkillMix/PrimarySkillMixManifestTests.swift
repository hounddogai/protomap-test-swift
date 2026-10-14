@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimarySkillMixManifestTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newPrimarySkillMixManifest("code-621", title: "title-276")
        #expect(item.status == Staffing.PrimarySkillMixManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Staffing.newPrimarySkillMixManifest("code-621", title: "title-276")
        try item.moveTo(Staffing.PrimarySkillMixManifestStatus.resolved)
        #expect(item.status == Staffing.PrimarySkillMixManifestStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newPrimarySkillMixManifest("code-621", title: "title-276")
        item.status = Staffing.PrimarySkillMixManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimarySkillMixManifestStatus.`open`) }
    }
}
