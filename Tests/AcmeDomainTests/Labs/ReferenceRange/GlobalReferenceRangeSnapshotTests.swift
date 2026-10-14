@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalReferenceRangeSnapshotTests {
    @Test func startsInNew() throws {
        let item = Labs.newGlobalReferenceRangeSnapshot("code-727", label: "label-70")
        #expect(item.status == Labs.GlobalReferenceRangeSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newGlobalReferenceRangeSnapshot("code-727", label: "label-70")
        try item.moveTo(Labs.GlobalReferenceRangeSnapshotStatus.queued)
        #expect(item.status == Labs.GlobalReferenceRangeSnapshotStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newGlobalReferenceRangeSnapshot("code-727", label: "label-70")
        item.status = Labs.GlobalReferenceRangeSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.GlobalReferenceRangeSnapshotStatus.new) }
    }
}
