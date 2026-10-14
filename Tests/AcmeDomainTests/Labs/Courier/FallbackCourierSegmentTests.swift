@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierSegmentTests {
    @Test func startsInCreated() throws {
        let item = Labs.newFallbackCourierSegment("code-828", title: "title-294")
        #expect(item.status == Labs.FallbackCourierSegmentStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Labs.newFallbackCourierSegment("code-828", title: "title-294")
        try item.moveTo(Labs.FallbackCourierSegmentStatus.validated)
        #expect(item.status == Labs.FallbackCourierSegmentStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Labs.newFallbackCourierSegment("code-828", title: "title-294")
        item.status = Labs.FallbackCourierSegmentStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackCourierSegmentStatus.created) }
    }
}
