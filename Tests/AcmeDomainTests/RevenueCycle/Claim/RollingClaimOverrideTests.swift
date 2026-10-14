@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingClaimOverrideTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRollingClaimOverride("code-822", title: "title-376")
        #expect(item.status == RevenueCycle.RollingClaimOverrideStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newRollingClaimOverride("code-822", title: "title-376")
        try item.moveTo(RevenueCycle.RollingClaimOverrideStatus.running)
        #expect(item.status == RevenueCycle.RollingClaimOverrideStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRollingClaimOverride("code-822", title: "title-376")
        item.status = RevenueCycle.RollingClaimOverrideStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingClaimOverrideStatus.new) }
    }
}
