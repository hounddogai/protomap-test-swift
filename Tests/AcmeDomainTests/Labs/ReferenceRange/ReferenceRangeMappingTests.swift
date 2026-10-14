@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeMappingTests {
    @Test func startsInIdle() throws {
        let item = Labs.newReferenceRangeMapping("code-343", name: "name-158")
        #expect(item.status == Labs.ReferenceRangeMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newReferenceRangeMapping("code-343", name: "name-158")
        try item.moveTo(Labs.ReferenceRangeMappingStatus.draining)
        #expect(item.status == Labs.ReferenceRangeMappingStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newReferenceRangeMapping("code-343", name: "name-158")
        item.status = Labs.ReferenceRangeMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeMappingStatus.idle) }
    }
}
