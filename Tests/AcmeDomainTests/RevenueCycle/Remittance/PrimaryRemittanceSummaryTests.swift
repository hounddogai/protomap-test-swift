@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceSummaryTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newPrimaryRemittanceSummary("code-261", label: "label-113")
        #expect(item.status == RevenueCycle.PrimaryRemittanceSummaryStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newPrimaryRemittanceSummary("code-261", label: "label-113")
        try item.moveTo(RevenueCycle.PrimaryRemittanceSummaryStatus.withdrawn)
        #expect(item.status == RevenueCycle.PrimaryRemittanceSummaryStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newPrimaryRemittanceSummary("code-261", label: "label-113")
        item.status = RevenueCycle.PrimaryRemittanceSummaryStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.PrimaryRemittanceSummaryStatus.proposed) }
    }
}
