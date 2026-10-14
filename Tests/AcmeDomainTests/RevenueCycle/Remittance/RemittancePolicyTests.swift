@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittancePolicyTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRemittancePolicy("code-665", title: "title-642")
        #expect(item.status == RevenueCycle.RemittancePolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newRemittancePolicy("code-665", title: "title-642")
        try item.moveTo(RevenueCycle.RemittancePolicyStatus.stopped)
        #expect(item.status == RevenueCycle.RemittancePolicyStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRemittancePolicy("code-665", title: "title-642")
        item.status = RevenueCycle.RemittancePolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittancePolicyStatus.idle) }
    }
}
