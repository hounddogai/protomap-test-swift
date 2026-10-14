@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledResultPolicyTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newScheduledResultPolicy("code-851", title: "title-224")
        #expect(item.status == Labs.ScheduledResultPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newScheduledResultPolicy("code-851", title: "title-224")
        try item.moveTo(Labs.ScheduledResultPolicyStatus.completed)
        #expect(item.status == Labs.ScheduledResultPolicyStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newScheduledResultPolicy("code-851", title: "title-224")
        item.status = Labs.ScheduledResultPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ScheduledResultPolicyStatus.planned) }
    }
}
