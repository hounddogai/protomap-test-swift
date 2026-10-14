@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalEntryTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newGlobalGoalEntry("code-936", label: "label-39")
        #expect(item.status == CareManagement.GlobalGoalEntryStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = CareManagement.newGlobalGoalEntry("code-936", label: "label-39")
        try item.moveTo(CareManagement.GlobalGoalEntryStatus.scheduled)
        #expect(item.status == CareManagement.GlobalGoalEntryStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newGlobalGoalEntry("code-936", label: "label-39")
        item.status = CareManagement.GlobalGoalEntryStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.GlobalGoalEntryStatus.planned) }
    }
}
