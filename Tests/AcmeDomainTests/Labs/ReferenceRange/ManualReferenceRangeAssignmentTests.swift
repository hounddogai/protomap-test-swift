@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualReferenceRangeAssignmentTests {
    @Test func startsInNew() throws {
        let item = Labs.newManualReferenceRangeAssignment("code-646", name: "name-779")
        #expect(item.status == Labs.ManualReferenceRangeAssignmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newManualReferenceRangeAssignment("code-646", name: "name-779")
        try item.moveTo(Labs.ManualReferenceRangeAssignmentStatus.running)
        #expect(item.status == Labs.ManualReferenceRangeAssignmentStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newManualReferenceRangeAssignment("code-646", name: "name-779")
        item.status = Labs.ManualReferenceRangeAssignmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualReferenceRangeAssignmentStatus.new) }
    }
}
