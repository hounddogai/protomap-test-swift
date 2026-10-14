@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeNoticeTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newChargeNotice("code-262", name: "name-164")
        #expect(item.status == RevenueCycle.ChargeNoticeStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newChargeNotice("code-262", name: "name-164")
        try item.moveTo(RevenueCycle.ChargeNoticeStatus.scheduled)
        #expect(item.status == RevenueCycle.ChargeNoticeStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newChargeNotice("code-262", name: "name-164")
        item.status = RevenueCycle.ChargeNoticeStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeNoticeStatus.planned) }
    }
}
