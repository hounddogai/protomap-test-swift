@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalClaimProfileTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newRegionalClaimProfile("code-247", title: "title-866")
        #expect(item.status == RevenueCycle.RegionalClaimProfileStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newRegionalClaimProfile("code-247", title: "title-866")
        try item.moveTo(RevenueCycle.RegionalClaimProfileStatus.approved)
        #expect(item.status == RevenueCycle.RegionalClaimProfileStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newRegionalClaimProfile("code-247", title: "title-866")
        item.status = RevenueCycle.RegionalClaimProfileStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalClaimProfileStatus.proposed) }
    }
}
