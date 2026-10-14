@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachRequestTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newScheduledOutreachRequest("code-472", name: "name-381")
        #expect(item.status == CareManagement.ScheduledOutreachRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = CareManagement.newScheduledOutreachRequest("code-472", name: "name-381")
        try item.moveTo(CareManagement.ScheduledOutreachRequestStatus.suspended)
        #expect(item.status == CareManagement.ScheduledOutreachRequestStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newScheduledOutreachRequest("code-472", name: "name-381")
        item.status = CareManagement.ScheduledOutreachRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledOutreachRequestStatus.draft) }
    }
}
