@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledChargeDigestTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newScheduledChargeDigest("code-177", name: "name-261")
        #expect(item.status == RevenueCycle.ScheduledChargeDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = RevenueCycle.newScheduledChargeDigest("code-177", name: "name-261")
        try item.moveTo(RevenueCycle.ScheduledChargeDigestStatus.suspended)
        #expect(item.status == RevenueCycle.ScheduledChargeDigestStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newScheduledChargeDigest("code-177", name: "name-261")
        item.status = RevenueCycle.ScheduledChargeDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledChargeDigestStatus.draft) }
    }
}
