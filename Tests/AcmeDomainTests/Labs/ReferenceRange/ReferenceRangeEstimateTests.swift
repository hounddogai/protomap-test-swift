@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeEstimateTests {
    @Test func startsInIdle() throws {
        let item = Labs.newReferenceRangeEstimate("code-331", title: "title-540")
        #expect(item.status == Labs.ReferenceRangeEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Labs.newReferenceRangeEstimate("code-331", title: "title-540")
        try item.moveTo(Labs.ReferenceRangeEstimateStatus.draining)
        #expect(item.status == Labs.ReferenceRangeEstimateStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newReferenceRangeEstimate("code-331", title: "title-540")
        item.status = Labs.ReferenceRangeEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeEstimateStatus.idle) }
    }
}
