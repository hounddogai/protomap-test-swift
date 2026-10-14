@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingDenialLedgerTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newPendingDenialLedger("code-755", title: "title-84")
        #expect(item.status == RevenueCycle.PendingDenialLedgerStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newPendingDenialLedger("code-755", title: "title-84")
        try item.moveTo(RevenueCycle.PendingDenialLedgerStatus.ready)
        #expect(item.status == RevenueCycle.PendingDenialLedgerStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newPendingDenialLedger("code-755", title: "title-84")
        item.status = RevenueCycle.PendingDenialLedgerStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PendingDenialLedgerStatus.idle) }
    }
}
