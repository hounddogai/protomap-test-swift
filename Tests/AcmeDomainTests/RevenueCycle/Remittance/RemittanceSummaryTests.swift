@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceSummaryTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRemittanceSummary("code-810", label: "label-312")
        #expect(item.status == RevenueCycle.RemittanceSummaryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newRemittanceSummary("code-810", label: "label-312")
        try item.moveTo(RevenueCycle.RemittanceSummaryStatus.ready)
        #expect(item.status == RevenueCycle.RemittanceSummaryStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRemittanceSummary("code-810", label: "label-312")
        item.status = RevenueCycle.RemittanceSummaryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceSummaryStatus.idle) }
    }
}
