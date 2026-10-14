@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeBundleTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newChargeBundle("code-660", title: "title-753")
        #expect(item.status == RevenueCycle.ChargeBundleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = RevenueCycle.newChargeBundle("code-660", title: "title-753")
        try item.moveTo(RevenueCycle.ChargeBundleStatus.stopped)
        #expect(item.status == RevenueCycle.ChargeBundleStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newChargeBundle("code-660", title: "title-753")
        item.status = RevenueCycle.ChargeBundleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeBundleStatus.idle) }
    }
}
