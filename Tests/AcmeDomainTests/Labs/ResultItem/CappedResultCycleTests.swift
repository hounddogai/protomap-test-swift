@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedResultCycleTests {
    @Test func startsInCreated() throws {
        let item = Labs.newCappedResultCycle("code-207", label: "label-532")
        #expect(item.status == Labs.CappedResultCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newCappedResultCycle("code-207", label: "label-532")
        try item.moveTo(Labs.CappedResultCycleStatus.validated)
        #expect(item.status == Labs.CappedResultCycleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newCappedResultCycle("code-207", label: "label-532")
        item.status = Labs.CappedResultCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedResultCycleStatus.created) }
    }
}
