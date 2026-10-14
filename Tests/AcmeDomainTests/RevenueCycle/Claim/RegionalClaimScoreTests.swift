@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalClaimScoreTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newRegionalClaimScore("code-512", label: "label-534")
        #expect(item.status == RevenueCycle.RegionalClaimScoreStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newRegionalClaimScore("code-512", label: "label-534")
        try item.moveTo(RevenueCycle.RegionalClaimScoreStatus.granted)
        #expect(item.status == RevenueCycle.RegionalClaimScoreStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newRegionalClaimScore("code-512", label: "label-534")
        item.status = RevenueCycle.RegionalClaimScoreStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalClaimScoreStatus.requested) }
    }
}
