@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualCourierEstimateTests {
    @Test func startsInNew() throws {
        let item = Labs.newManualCourierEstimate("code-9", label: "label-850")
        #expect(item.status == Labs.ManualCourierEstimateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newManualCourierEstimate("code-9", label: "label-850")
        try item.moveTo(Labs.ManualCourierEstimateStatus.queued)
        #expect(item.status == Labs.ManualCourierEstimateStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newManualCourierEstimate("code-9", label: "label-850")
        item.status = Labs.ManualCourierEstimateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualCourierEstimateStatus.new) }
    }
}
