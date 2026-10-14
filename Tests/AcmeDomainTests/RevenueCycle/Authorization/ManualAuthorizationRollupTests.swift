@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualAuthorizationRollupTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newManualAuthorizationRollup("code-195", label: "label-947")
        #expect(item.status == RevenueCycle.ManualAuthorizationRollupStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newManualAuthorizationRollup("code-195", label: "label-947")
        try item.moveTo(RevenueCycle.ManualAuthorizationRollupStatus.active)
        #expect(item.status == RevenueCycle.ManualAuthorizationRollupStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newManualAuthorizationRollup("code-195", label: "label-947")
        item.status = RevenueCycle.ManualAuthorizationRollupStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualAuthorizationRollupStatus.draft) }
    }
}
