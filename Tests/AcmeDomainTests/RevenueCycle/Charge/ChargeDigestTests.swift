@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeDigestTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newChargeDigest("code-349", title: "title-805")
        #expect(item.status == RevenueCycle.ChargeDigestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newChargeDigest("code-349", title: "title-805")
        try item.moveTo(RevenueCycle.ChargeDigestStatus.done)
        #expect(item.status == RevenueCycle.ChargeDigestStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newChargeDigest("code-349", title: "title-805")
        item.status = RevenueCycle.ChargeDigestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeDigestStatus.new) }
    }
}
