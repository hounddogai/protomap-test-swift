@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceRollupTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRemittanceRollup("code-301", name: "name-414")
        #expect(item.status == RevenueCycle.RemittanceRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newRemittanceRollup("code-301", name: "name-414")
        try item.moveTo(RevenueCycle.RemittanceRollupStatus.granted)
        #expect(item.status == RevenueCycle.RemittanceRollupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRemittanceRollup("code-301", name: "name-414")
        item.status = RevenueCycle.RemittanceRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceRollupStatus.requested) }
    }
}
