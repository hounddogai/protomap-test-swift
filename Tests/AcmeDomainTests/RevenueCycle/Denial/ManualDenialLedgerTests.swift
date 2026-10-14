@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialLedgerTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newManualDenialLedger("code-602", name: "name-550")
        #expect(item.status == RevenueCycle.ManualDenialLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = RevenueCycle.newManualDenialLedger("code-602", name: "name-550")
        try item.moveTo(RevenueCycle.ManualDenialLedgerStatus.validated)
        #expect(item.status == RevenueCycle.ManualDenialLedgerStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newManualDenialLedger("code-602", name: "name-550")
        item.status = RevenueCycle.ManualDenialLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualDenialLedgerStatus.created) }
    }
}
