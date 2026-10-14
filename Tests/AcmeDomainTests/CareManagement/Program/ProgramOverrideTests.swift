@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementProgramOverrideTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newProgramOverride("code-82", name: "name-271")
        #expect(item.status == CareManagement.ProgramOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newProgramOverride("code-82", name: "name-271")
        try item.moveTo(CareManagement.ProgramOverrideStatus.suspended)
        #expect(item.status == CareManagement.ProgramOverrideStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newProgramOverride("code-82", name: "name-271")
        item.status = CareManagement.ProgramOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ProgramOverrideStatus.draft) }
    }
}
