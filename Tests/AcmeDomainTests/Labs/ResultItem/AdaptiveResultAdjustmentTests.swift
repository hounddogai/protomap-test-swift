@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultAdjustmentTests {
    @Test func startsInNew() throws {
        let item = Labs.newAdaptiveResultAdjustment("code-361", label: "label-189")
        #expect(item.status == Labs.AdaptiveResultAdjustmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newAdaptiveResultAdjustment("code-361", label: "label-189")
        try item.moveTo(Labs.AdaptiveResultAdjustmentStatus.queued)
        #expect(item.status == Labs.AdaptiveResultAdjustmentStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newAdaptiveResultAdjustment("code-361", label: "label-189")
        item.status = Labs.AdaptiveResultAdjustmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.AdaptiveResultAdjustmentStatus.new) }
    }
}
