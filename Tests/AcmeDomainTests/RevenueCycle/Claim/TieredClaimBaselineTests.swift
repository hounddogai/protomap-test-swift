@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimBaselineTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newTieredClaimBaseline("code-732", label: "label-465")
        #expect(item.status == RevenueCycle.TieredClaimBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newTieredClaimBaseline("code-732", label: "label-465")
        try item.moveTo(RevenueCycle.TieredClaimBaselineStatus.granted)
        #expect(item.status == RevenueCycle.TieredClaimBaselineStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newTieredClaimBaseline("code-732", label: "label-465")
        item.status = RevenueCycle.TieredClaimBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredClaimBaselineStatus.requested) }
    }
}
