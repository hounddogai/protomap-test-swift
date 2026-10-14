@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledProgramProfileTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newScheduledProgramProfile("code-15", title: "title-468")
        #expect(item.status == CareManagement.ScheduledProgramProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newScheduledProgramProfile("code-15", title: "title-468")
        try item.moveTo(CareManagement.ScheduledProgramProfileStatus.suspended)
        #expect(item.status == CareManagement.ScheduledProgramProfileStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newScheduledProgramProfile("code-15", title: "title-468")
        item.status = CareManagement.ScheduledProgramProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledProgramProfileStatus.draft) }
    }
}
