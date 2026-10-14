@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierSegmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newCourierSegment("code-519", title: "title-262")
        #expect(item.status == Labs.CourierSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newCourierSegment("code-519", title: "title-262")
        try item.moveTo(Labs.CourierSegmentStatus.closed)
        #expect(item.status == Labs.CourierSegmentStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newCourierSegment("code-519", title: "title-262")
        item.status = Labs.CourierSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CourierSegmentStatus.draft) }
    }
}
