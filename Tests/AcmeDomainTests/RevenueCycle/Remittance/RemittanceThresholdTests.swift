@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceThresholdTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRemittanceThreshold("code-699", title: "title-19")
        #expect(item.status == RevenueCycle.RemittanceThresholdStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newRemittanceThreshold("code-699", title: "title-19")
        try item.moveTo(RevenueCycle.RemittanceThresholdStatus.running)
        #expect(item.status == RevenueCycle.RemittanceThresholdStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRemittanceThreshold("code-699", title: "title-19")
        item.status = RevenueCycle.RemittanceThresholdStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceThresholdStatus.new) }
    }
}
