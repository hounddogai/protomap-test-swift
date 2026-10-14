@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSegmentTests {
    @Test func startsInRequested() throws {
        let item = Labs.newResultSegment("code-457", label: "label-798")
        #expect(item.status == Labs.ResultSegmentStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Labs.newResultSegment("code-457", label: "label-798")
        try item.moveTo(Labs.ResultSegmentStatus.revoked)
        #expect(item.status == Labs.ResultSegmentStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newResultSegment("code-457", label: "label-798")
        item.status = Labs.ResultSegmentStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ResultSegmentStatus.requested) }
    }
}
