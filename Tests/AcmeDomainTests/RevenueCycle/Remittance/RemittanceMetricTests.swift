@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceMetricTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRemittanceMetric("code-500", title: "title-791")
        #expect(item.status == RevenueCycle.RemittanceMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newRemittanceMetric("code-500", title: "title-791")
        try item.moveTo(RevenueCycle.RemittanceMetricStatus.warming)
        #expect(item.status == RevenueCycle.RemittanceMetricStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRemittanceMetric("code-500", title: "title-791")
        item.status = RevenueCycle.RemittanceMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceMetricStatus.idle) }
    }
}
