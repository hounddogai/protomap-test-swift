@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyClaimProfileTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newLegacyClaimProfile("code-683", name: "name-993")
        #expect(item.status == RevenueCycle.LegacyClaimProfileStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = RevenueCycle.newLegacyClaimProfile("code-683", name: "name-993")
        try item.moveTo(RevenueCycle.LegacyClaimProfileStatus.running)
        #expect(item.status == RevenueCycle.LegacyClaimProfileStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newLegacyClaimProfile("code-683", name: "name-993")
        item.status = RevenueCycle.LegacyClaimProfileStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LegacyClaimProfileStatus.new) }
    }
}
