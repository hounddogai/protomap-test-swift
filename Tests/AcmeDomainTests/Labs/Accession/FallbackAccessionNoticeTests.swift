@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionNoticeTests {
    @Test func startsInRequested() throws {
        let item = Labs.newFallbackAccessionNotice("code-286", name: "name-346")
        #expect(item.status == Labs.FallbackAccessionNoticeStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newFallbackAccessionNotice("code-286", name: "name-346")
        try item.moveTo(Labs.FallbackAccessionNoticeStatus.granted)
        #expect(item.status == Labs.FallbackAccessionNoticeStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newFallbackAccessionNotice("code-286", name: "name-346")
        item.status = Labs.FallbackAccessionNoticeStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.FallbackAccessionNoticeStatus.requested) }
    }
}
