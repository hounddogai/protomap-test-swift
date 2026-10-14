@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingDenialVarianceTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newPendingDenialVariance("code-344", title: "title-616")
        #expect(item.status == RevenueCycle.PendingDenialVarianceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newPendingDenialVariance("code-344", title: "title-616")
        try item.moveTo(RevenueCycle.PendingDenialVarianceStatus.ready)
        #expect(item.status == RevenueCycle.PendingDenialVarianceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newPendingDenialVariance("code-344", title: "title-616")
        item.status = RevenueCycle.PendingDenialVarianceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingDenialVarianceStatus.idle) }
    }
}
