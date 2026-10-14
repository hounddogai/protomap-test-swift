@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBundleTests {
    @Test func startsInIdle() throws {
        let item = Labs.newReferenceRangeBundle("code-687", label: "label-159")
        #expect(item.status == Labs.ReferenceRangeBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newReferenceRangeBundle("code-687", label: "label-159")
        try item.moveTo(Labs.ReferenceRangeBundleStatus.draining)
        #expect(item.status == Labs.ReferenceRangeBundleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newReferenceRangeBundle("code-687", label: "label-159")
        item.status = Labs.ReferenceRangeBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeBundleStatus.idle) }
    }
}
