@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeScoreTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newChargeScore("code-547", title: "title-153")
        #expect(item.status == RevenueCycle.ChargeScoreStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newChargeScore("code-547", title: "title-153")
        try item.moveTo(RevenueCycle.ChargeScoreStatus.scheduled)
        #expect(item.status == RevenueCycle.ChargeScoreStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newChargeScore("code-547", title: "title-153")
        item.status = RevenueCycle.ChargeScoreStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeScoreStatus.planned) }
    }
}
