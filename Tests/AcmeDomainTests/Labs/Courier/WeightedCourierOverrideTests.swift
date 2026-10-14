@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsWeightedCourierOverrideTests {
    @Test func startsInNew() throws {
        let item = Labs.newWeightedCourierOverride("code-774", label: "label-786")
        #expect(item.status == Labs.WeightedCourierOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newWeightedCourierOverride("code-774", label: "label-786")
        try item.moveTo(Labs.WeightedCourierOverrideStatus.queued)
        #expect(item.status == Labs.WeightedCourierOverrideStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newWeightedCourierOverride("code-774", label: "label-786")
        item.status = Labs.WeightedCourierOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.WeightedCourierOverrideStatus.new) }
    }
}
