@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingChargeRecordTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newRollingChargeRecord("code-631", name: "name-803")
        #expect(item.status == RevenueCycle.RollingChargeRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = RevenueCycle.newRollingChargeRecord("code-631", name: "name-803")
        try item.moveTo(RevenueCycle.RollingChargeRecordStatus.ready)
        #expect(item.status == RevenueCycle.RollingChargeRecordStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newRollingChargeRecord("code-631", name: "name-803")
        item.status = RevenueCycle.RollingChargeRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingChargeRecordStatus.idle) }
    }
}
