@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramDraftTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRollingProgramDraft("code-199", name: "name-825")
        #expect(item.status == CareManagement.RollingProgramDraftStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newRollingProgramDraft("code-199", name: "name-825")
        try item.moveTo(CareManagement.RollingProgramDraftStatus.inProgress)
        #expect(item.status == CareManagement.RollingProgramDraftStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRollingProgramDraft("code-199", name: "name-825")
        item.status = CareManagement.RollingProgramDraftStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RollingProgramDraftStatus.planned) }
    }
}
