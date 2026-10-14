@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualSpecimenSegmentTests {
    @Test func startsInNew() throws {
        let item = Labs.newManualSpecimenSegment("code-657", title: "title-927")
        #expect(item.status == Labs.ManualSpecimenSegmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Labs.newManualSpecimenSegment("code-657", title: "title-927")
        try item.moveTo(Labs.ManualSpecimenSegmentStatus.done)
        #expect(item.status == Labs.ManualSpecimenSegmentStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newManualSpecimenSegment("code-657", title: "title-927")
        item.status = Labs.ManualSpecimenSegmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualSpecimenSegmentStatus.new) }
    }
}
