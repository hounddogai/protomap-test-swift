@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalDenialOverrideTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRegionalDenialOverride("code-775", title: "title-700")
        #expect(item.status == RevenueCycle.RegionalDenialOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newRegionalDenialOverride("code-775", title: "title-700")
        try item.moveTo(RevenueCycle.RegionalDenialOverrideStatus.running)
        #expect(item.status == RevenueCycle.RegionalDenialOverrideStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRegionalDenialOverride("code-775", title: "title-700")
        item.status = RevenueCycle.RegionalDenialOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalDenialOverrideStatus.new) }
    }
}
