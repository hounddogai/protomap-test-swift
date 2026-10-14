@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimRollupTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newAdaptiveClaimRollup("code-634", name: "name-558")
        #expect(item.status == RevenueCycle.AdaptiveClaimRollupStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newAdaptiveClaimRollup("code-634", name: "name-558")
        try item.moveTo(RevenueCycle.AdaptiveClaimRollupStatus.scheduled)
        #expect(item.status == RevenueCycle.AdaptiveClaimRollupStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newAdaptiveClaimRollup("code-634", name: "name-558")
        item.status = RevenueCycle.AdaptiveClaimRollupStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveClaimRollupStatus.planned) }
    }
}
