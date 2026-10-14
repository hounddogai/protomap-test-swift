@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingDenialEntryTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRollingDenialEntry("code-269", label: "label-234")
        #expect(item.status == RevenueCycle.RollingDenialEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newRollingDenialEntry("code-269", label: "label-234")
        try item.moveTo(RevenueCycle.RollingDenialEntryStatus.running)
        #expect(item.status == RevenueCycle.RollingDenialEntryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRollingDenialEntry("code-269", label: "label-234")
        item.status = RevenueCycle.RollingDenialEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingDenialEntryStatus.new) }
    }
}
