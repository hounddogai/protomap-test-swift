@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeOverrideTests {
    @Test func startsInDraft() throws {
        let item = Labs.newReferenceRangeOverride("code-718", label: "label-339")
        #expect(item.status == Labs.ReferenceRangeOverrideStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newReferenceRangeOverride("code-718", label: "label-339")
        try item.moveTo(Labs.ReferenceRangeOverrideStatus.active)
        #expect(item.status == Labs.ReferenceRangeOverrideStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newReferenceRangeOverride("code-718", label: "label-339")
        item.status = Labs.ReferenceRangeOverrideStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeOverrideStatus.draft) }
    }
}
