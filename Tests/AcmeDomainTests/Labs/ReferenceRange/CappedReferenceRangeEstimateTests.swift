@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeEstimateTests {
    @Test func startsInIdle() throws {
        let item = Labs.newCappedReferenceRangeEstimate("code-303", name: "name-987")
        #expect(item.status == Labs.CappedReferenceRangeEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Labs.newCappedReferenceRangeEstimate("code-303", name: "name-987")
        try item.moveTo(Labs.CappedReferenceRangeEstimateStatus.ready)
        #expect(item.status == Labs.CappedReferenceRangeEstimateStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newCappedReferenceRangeEstimate("code-303", name: "name-987")
        item.status = Labs.CappedReferenceRangeEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedReferenceRangeEstimateStatus.idle) }
    }
}
