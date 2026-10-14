@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeLedgerTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newChargeLedger("code-393", title: "title-778")
        #expect(item.status == RevenueCycle.ChargeLedgerStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newChargeLedger("code-393", title: "title-778")
        try item.moveTo(RevenueCycle.ChargeLedgerStatus.published)
        #expect(item.status == RevenueCycle.ChargeLedgerStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newChargeLedger("code-393", title: "title-778")
        item.status = RevenueCycle.ChargeLedgerStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeLedgerStatus.created) }
    }
}
