@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientCourierGroupTests {
    @Test func startsInNew() throws {
        let item = Labs.newLenientCourierGroup("code-790", title: "title-461")
        #expect(item.status == Labs.LenientCourierGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newLenientCourierGroup("code-790", title: "title-461")
        try item.moveTo(Labs.LenientCourierGroupStatus.queued)
        #expect(item.status == Labs.LenientCourierGroupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newLenientCourierGroup("code-790", title: "title-461")
        item.status = Labs.LenientCourierGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LenientCourierGroupStatus.new) }
    }
}
