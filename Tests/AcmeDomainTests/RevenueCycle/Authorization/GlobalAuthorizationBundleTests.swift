@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalAuthorizationBundleTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newGlobalAuthorizationBundle("code-33", name: "name-525")
        #expect(item.status == RevenueCycle.GlobalAuthorizationBundleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = RevenueCycle.newGlobalAuthorizationBundle("code-33", name: "name-525")
        try item.moveTo(RevenueCycle.GlobalAuthorizationBundleStatus.cancelled)
        #expect(item.status == RevenueCycle.GlobalAuthorizationBundleStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newGlobalAuthorizationBundle("code-33", name: "name-525")
        item.status = RevenueCycle.GlobalAuthorizationBundleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalAuthorizationBundleStatus.planned) }
    }
}
