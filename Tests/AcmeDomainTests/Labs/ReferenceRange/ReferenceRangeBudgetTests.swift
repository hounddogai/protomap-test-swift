@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBudgetTests {
    @Test func startsInRequested() throws {
        let item = Labs.newReferenceRangeBudget("code-738", label: "label-22")
        #expect(item.status == Labs.ReferenceRangeBudgetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newReferenceRangeBudget("code-738", label: "label-22")
        try item.moveTo(Labs.ReferenceRangeBudgetStatus.granted)
        #expect(item.status == Labs.ReferenceRangeBudgetStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newReferenceRangeBudget("code-738", label: "label-22")
        item.status = Labs.ReferenceRangeBudgetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeBudgetStatus.requested) }
    }
}
