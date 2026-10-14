@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeExceptionTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newChargeException("code-327", title: "title-366")
        #expect(item.status == RevenueCycle.ChargeExceptionStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = RevenueCycle.newChargeException("code-327", title: "title-366")
        try item.moveTo(RevenueCycle.ChargeExceptionStatus.expired)
        #expect(item.status == RevenueCycle.ChargeExceptionStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newChargeException("code-327", title: "title-366")
        item.status = RevenueCycle.ChargeExceptionStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeExceptionStatus.requested) }
    }
}
