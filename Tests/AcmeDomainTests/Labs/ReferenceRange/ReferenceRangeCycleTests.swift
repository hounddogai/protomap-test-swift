@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeCycleTests {
    @Test func startsInDraft() throws {
        let item = Labs.newReferenceRangeCycle("code-153", label: "label-779")
        #expect(item.status == Labs.ReferenceRangeCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newReferenceRangeCycle("code-153", label: "label-779")
        try item.moveTo(Labs.ReferenceRangeCycleStatus.active)
        #expect(item.status == Labs.ReferenceRangeCycleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newReferenceRangeCycle("code-153", label: "label-779")
        item.status = Labs.ReferenceRangeCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeCycleStatus.draft) }
    }
}
