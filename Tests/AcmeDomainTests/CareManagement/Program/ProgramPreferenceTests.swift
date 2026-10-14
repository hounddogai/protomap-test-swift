@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramPreferenceTests {
    @Test func startsInCreated() throws {
        let item = CareManagement.newProgramPreference("code-149", title: "title-992")
        #expect(item.status == CareManagement.ProgramPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = CareManagement.newProgramPreference("code-149", title: "title-992")
        try item.moveTo(CareManagement.ProgramPreferenceStatus.published)
        #expect(item.status == CareManagement.ProgramPreferenceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = CareManagement.newProgramPreference("code-149", title: "title-992")
        item.status = CareManagement.ProgramPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramPreferenceStatus.created) }
    }
}
