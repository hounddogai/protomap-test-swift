@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingResultSegmentTests {
    @Test func startsInDraft() throws {
        let item = Labs.newRollingResultSegment("code-635", label: "label-746")
        #expect(item.status == Labs.RollingResultSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newRollingResultSegment("code-635", label: "label-746")
        try item.moveTo(Labs.RollingResultSegmentStatus.active)
        #expect(item.status == Labs.RollingResultSegmentStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newRollingResultSegment("code-635", label: "label-746")
        item.status = Labs.RollingResultSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.RollingResultSegmentStatus.draft) }
    }
}
