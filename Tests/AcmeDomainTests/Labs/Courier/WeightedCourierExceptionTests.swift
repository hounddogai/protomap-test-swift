@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierExceptionTests {
    @Test func startsInIdle() throws {
        let item = Labs.newWeightedCourierException("code-118", label: "label-277")
        #expect(item.status == Labs.WeightedCourierExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Labs.newWeightedCourierException("code-118", label: "label-277")
        try item.moveTo(Labs.WeightedCourierExceptionStatus.warming)
        #expect(item.status == Labs.WeightedCourierExceptionStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Labs.newWeightedCourierException("code-118", label: "label-277")
        item.status = Labs.WeightedCourierExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedCourierExceptionStatus.idle) }
    }
}
