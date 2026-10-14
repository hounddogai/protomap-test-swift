@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationBaselineTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newAuthorizationBaseline("code-354", label: "label-685")
        #expect(item.status == RevenueCycle.AuthorizationBaselineStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = RevenueCycle.newAuthorizationBaseline("code-354", label: "label-685")
        try item.moveTo(RevenueCycle.AuthorizationBaselineStatus.completed)
        #expect(item.status == RevenueCycle.AuthorizationBaselineStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newAuthorizationBaseline("code-354", label: "label-685")
        item.status = RevenueCycle.AuthorizationBaselineStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationBaselineStatus.planned) }
    }
}
