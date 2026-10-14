@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAdjustmentTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRemittanceAdjustment("code-16", label: "label-356")
        #expect(item.status == RevenueCycle.RemittanceAdjustmentStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newRemittanceAdjustment("code-16", label: "label-356")
        try item.moveTo(RevenueCycle.RemittanceAdjustmentStatus.done)
        #expect(item.status == RevenueCycle.RemittanceAdjustmentStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRemittanceAdjustment("code-16", label: "label-356")
        item.status = RevenueCycle.RemittanceAdjustmentStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceAdjustmentStatus.new) }
    }
}
