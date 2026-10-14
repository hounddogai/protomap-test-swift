@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeTierTests {
    @Test func startsInIdle() throws {
        let item = Labs.newReferenceRangeTier("code-323", label: "label-32")
        #expect(item.status == Labs.ReferenceRangeTierStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newReferenceRangeTier("code-323", label: "label-32")
        try item.moveTo(Labs.ReferenceRangeTierStatus.draining)
        #expect(item.status == Labs.ReferenceRangeTierStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newReferenceRangeTier("code-323", label: "label-32")
        item.status = Labs.ReferenceRangeTierStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeTierStatus.idle) }
    }
}
