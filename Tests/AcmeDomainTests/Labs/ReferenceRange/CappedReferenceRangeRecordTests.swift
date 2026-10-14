@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeRecordTests {
    @Test func startsInCreated() throws {
        let item = Labs.newCappedReferenceRangeRecord("code-746", title: "title-779")
        #expect(item.status == Labs.CappedReferenceRangeRecordStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newCappedReferenceRangeRecord("code-746", title: "title-779")
        try item.moveTo(Labs.CappedReferenceRangeRecordStatus.validated)
        #expect(item.status == Labs.CappedReferenceRangeRecordStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newCappedReferenceRangeRecord("code-746", title: "title-779")
        item.status = Labs.CappedReferenceRangeRecordStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedReferenceRangeRecordStatus.created) }
    }
}
