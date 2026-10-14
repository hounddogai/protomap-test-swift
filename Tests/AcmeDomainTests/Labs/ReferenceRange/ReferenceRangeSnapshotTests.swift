@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeSnapshotTests {
    @Test func startsInOpen() throws {
        let item = Labs.newReferenceRangeSnapshot("code-156", title: "title-520")
        #expect(item.status == Labs.ReferenceRangeSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newReferenceRangeSnapshot("code-156", title: "title-520")
        try item.moveTo(Labs.ReferenceRangeSnapshotStatus.resolved)
        #expect(item.status == Labs.ReferenceRangeSnapshotStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newReferenceRangeSnapshot("code-156", title: "title-520")
        item.status = Labs.ReferenceRangeSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeSnapshotStatus.`open`) }
    }
}
