@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeScheduleTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newChargeSchedule("code-591", name: "name-854")
        #expect(item.status == RevenueCycle.ChargeScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newChargeSchedule("code-591", name: "name-854")
        try item.moveTo(RevenueCycle.ChargeScheduleStatus.running)
        #expect(item.status == RevenueCycle.ChargeScheduleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newChargeSchedule("code-591", name: "name-854")
        item.status = RevenueCycle.ChargeScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeScheduleStatus.new) }
    }
}
