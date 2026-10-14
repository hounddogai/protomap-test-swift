@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeGroupTests {
    @Test func startsInDraft() throws {
        let item = Labs.newReferenceRangeGroup("code-635", label: "label-236")
        #expect(item.status == Labs.ReferenceRangeGroupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newReferenceRangeGroup("code-635", label: "label-236")
        try item.moveTo(Labs.ReferenceRangeGroupStatus.closed)
        #expect(item.status == Labs.ReferenceRangeGroupStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newReferenceRangeGroup("code-635", label: "label-236")
        item.status = Labs.ReferenceRangeGroupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeGroupStatus.draft) }
    }
}
