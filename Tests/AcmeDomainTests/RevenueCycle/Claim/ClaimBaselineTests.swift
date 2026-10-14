@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimBaselineTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newClaimBaseline("code-697", label: "label-570")
        #expect(item.status == RevenueCycle.ClaimBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newClaimBaseline("code-697", label: "label-570")
        try item.moveTo(RevenueCycle.ClaimBaselineStatus.granted)
        #expect(item.status == RevenueCycle.ClaimBaselineStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newClaimBaseline("code-697", label: "label-570")
        item.status = RevenueCycle.ClaimBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimBaselineStatus.requested) }
    }
}
