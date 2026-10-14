@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveSpecimenSnapshotTests {
    @Test func startsInNew() throws {
        let item = Labs.newAdaptiveSpecimenSnapshot("code-770", title: "title-281")
        #expect(item.status == Labs.AdaptiveSpecimenSnapshotStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newAdaptiveSpecimenSnapshot("code-770", title: "title-281")
        try item.moveTo(Labs.AdaptiveSpecimenSnapshotStatus.queued)
        #expect(item.status == Labs.AdaptiveSpecimenSnapshotStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newAdaptiveSpecimenSnapshot("code-770", title: "title-281")
        item.status = Labs.AdaptiveSpecimenSnapshotStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveSpecimenSnapshotStatus.new) }
    }
}
