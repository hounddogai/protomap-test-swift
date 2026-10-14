@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledDenialBaselineTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newScheduledDenialBaseline("code-642", name: "name-81")
        #expect(item.status == RevenueCycle.ScheduledDenialBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newScheduledDenialBaseline("code-642", name: "name-81")
        try item.moveTo(RevenueCycle.ScheduledDenialBaselineStatus.running)
        #expect(item.status == RevenueCycle.ScheduledDenialBaselineStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newScheduledDenialBaseline("code-642", name: "name-81")
        item.status = RevenueCycle.ScheduledDenialBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledDenialBaselineStatus.new) }
    }
}
