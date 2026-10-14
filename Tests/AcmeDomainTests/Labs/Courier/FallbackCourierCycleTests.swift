@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierCycleTests {
    @Test func startsInDraft() throws {
        let item = Labs.newFallbackCourierCycle("code-686", label: "label-749")
        #expect(item.status == Labs.FallbackCourierCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newFallbackCourierCycle("code-686", label: "label-749")
        try item.moveTo(Labs.FallbackCourierCycleStatus.pending)
        #expect(item.status == Labs.FallbackCourierCycleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newFallbackCourierCycle("code-686", label: "label-749")
        item.status = Labs.FallbackCourierCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackCourierCycleStatus.draft) }
    }
}
