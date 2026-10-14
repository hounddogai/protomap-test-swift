@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeTierTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newChargeTier("code-863", name: "name-231")
        #expect(item.status == RevenueCycle.ChargeTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = RevenueCycle.newChargeTier("code-863", name: "name-231")
        try item.moveTo(RevenueCycle.ChargeTierStatus.active)
        #expect(item.status == RevenueCycle.ChargeTierStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newChargeTier("code-863", name: "name-231")
        item.status = RevenueCycle.ChargeTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeTierStatus.draft) }
    }
}
