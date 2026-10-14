@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceExceptionTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newTieredRemittanceException("code-129", title: "title-686")
        #expect(item.status == RevenueCycle.TieredRemittanceExceptionStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newTieredRemittanceException("code-129", title: "title-686")
        try item.moveTo(RevenueCycle.TieredRemittanceExceptionStatus.withdrawn)
        #expect(item.status == RevenueCycle.TieredRemittanceExceptionStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newTieredRemittanceException("code-129", title: "title-686")
        item.status = RevenueCycle.TieredRemittanceExceptionStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredRemittanceExceptionStatus.proposed) }
    }
}
