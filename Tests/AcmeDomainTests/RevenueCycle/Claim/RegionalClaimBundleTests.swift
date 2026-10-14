@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalClaimBundleTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newRegionalClaimBundle("code-163", label: "label-840")
        #expect(item.status == RevenueCycle.RegionalClaimBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newRegionalClaimBundle("code-163", label: "label-840")
        try item.moveTo(RevenueCycle.RegionalClaimBundleStatus.approved)
        #expect(item.status == RevenueCycle.RegionalClaimBundleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newRegionalClaimBundle("code-163", label: "label-840")
        item.status = RevenueCycle.RegionalClaimBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalClaimBundleStatus.proposed) }
    }
}
