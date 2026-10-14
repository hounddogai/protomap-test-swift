@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientReferenceRangeDraftTests {
    @Test func startsInCreated() throws {
        let item = Labs.newLenientReferenceRangeDraft("code-250", title: "title-55")
        #expect(item.status == Labs.LenientReferenceRangeDraftStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Labs.newLenientReferenceRangeDraft("code-250", title: "title-55")
        try item.moveTo(Labs.LenientReferenceRangeDraftStatus.published)
        #expect(item.status == Labs.LenientReferenceRangeDraftStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newLenientReferenceRangeDraft("code-250", title: "title-55")
        item.status = Labs.LenientReferenceRangeDraftStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientReferenceRangeDraftStatus.created) }
    }
}
