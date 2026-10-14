@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenSegmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSpecimenSegment("code-860", name: "name-318")
        #expect(item.status == Labs.SpecimenSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newSpecimenSegment("code-860", name: "name-318")
        try item.moveTo(Labs.SpecimenSegmentStatus.closed)
        #expect(item.status == Labs.SpecimenSegmentStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSpecimenSegment("code-860", name: "name-318")
        item.status = Labs.SpecimenSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenSegmentStatus.draft) }
    }
}
