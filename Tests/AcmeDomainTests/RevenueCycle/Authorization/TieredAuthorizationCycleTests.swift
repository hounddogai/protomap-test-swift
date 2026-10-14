@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredAuthorizationCycleTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newTieredAuthorizationCycle("code-794", name: "name-376")
        #expect(item.status == RevenueCycle.TieredAuthorizationCycleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newTieredAuthorizationCycle("code-794", name: "name-376")
        try item.moveTo(RevenueCycle.TieredAuthorizationCycleStatus.active)
        #expect(item.status == RevenueCycle.TieredAuthorizationCycleStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newTieredAuthorizationCycle("code-794", name: "name-376")
        item.status = RevenueCycle.TieredAuthorizationCycleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredAuthorizationCycleStatus.draft) }
    }
}
