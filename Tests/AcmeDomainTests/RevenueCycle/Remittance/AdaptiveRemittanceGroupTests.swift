@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveRemittanceGroupTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newAdaptiveRemittanceGroup("code-788", title: "title-488")
        #expect(item.status == RevenueCycle.AdaptiveRemittanceGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = RevenueCycle.newAdaptiveRemittanceGroup("code-788", title: "title-488")
        try item.moveTo(RevenueCycle.AdaptiveRemittanceGroupStatus.approved)
        #expect(item.status == RevenueCycle.AdaptiveRemittanceGroupStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newAdaptiveRemittanceGroup("code-788", title: "title-488")
        item.status = RevenueCycle.AdaptiveRemittanceGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveRemittanceGroupStatus.proposed) }
    }
}
