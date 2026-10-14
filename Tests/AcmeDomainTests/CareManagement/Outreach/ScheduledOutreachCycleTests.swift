@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledOutreachCycleTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newScheduledOutreachCycle("code-164", label: "label-379")
        #expect(item.status == CareManagement.ScheduledOutreachCycleStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newScheduledOutreachCycle("code-164", label: "label-379")
        try item.moveTo(CareManagement.ScheduledOutreachCycleStatus.granted)
        #expect(item.status == CareManagement.ScheduledOutreachCycleStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newScheduledOutreachCycle("code-164", label: "label-379")
        item.status = CareManagement.ScheduledOutreachCycleStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.ScheduledOutreachCycleStatus.requested) }
    }
}
