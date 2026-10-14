@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialMetricTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newDenialMetric("code-213", name: "name-368")
        #expect(item.status == RevenueCycle.DenialMetricStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newDenialMetric("code-213", name: "name-368")
        try item.moveTo(RevenueCycle.DenialMetricStatus.active)
        #expect(item.status == RevenueCycle.DenialMetricStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newDenialMetric("code-213", name: "name-368")
        item.status = RevenueCycle.DenialMetricStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialMetricStatus.draft) }
    }
}
