@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeExceptionTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDefaultChargeException("code-244", name: "name-590")
        #expect(item.status == RevenueCycle.DefaultChargeExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newDefaultChargeException("code-244", name: "name-590")
        try item.moveTo(RevenueCycle.DefaultChargeExceptionStatus.withdrawn)
        #expect(item.status == RevenueCycle.DefaultChargeExceptionStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDefaultChargeException("code-244", name: "name-590")
        item.status = RevenueCycle.DefaultChargeExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DefaultChargeExceptionStatus.proposed) }
    }
}
