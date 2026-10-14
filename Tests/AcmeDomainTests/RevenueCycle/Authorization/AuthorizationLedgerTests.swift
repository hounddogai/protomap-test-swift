@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationLedgerTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newAuthorizationLedger("code-866", label: "label-923")
        #expect(item.status == RevenueCycle.AuthorizationLedgerStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = RevenueCycle.newAuthorizationLedger("code-866", label: "label-923")
        try item.moveTo(RevenueCycle.AuthorizationLedgerStatus.archived)
        #expect(item.status == RevenueCycle.AuthorizationLedgerStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newAuthorizationLedger("code-866", label: "label-923")
        item.status = RevenueCycle.AuthorizationLedgerStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationLedgerStatus.`open`) }
    }
}
