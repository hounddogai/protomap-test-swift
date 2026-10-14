@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeVarianceTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newChargeVariance("code-920", title: "title-76")
        #expect(item.status == RevenueCycle.ChargeVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newChargeVariance("code-920", title: "title-76")
        try item.moveTo(RevenueCycle.ChargeVarianceStatus.granted)
        #expect(item.status == RevenueCycle.ChargeVarianceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newChargeVariance("code-920", title: "title-76")
        item.status = RevenueCycle.ChargeVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeVarianceStatus.requested) }
    }
}
