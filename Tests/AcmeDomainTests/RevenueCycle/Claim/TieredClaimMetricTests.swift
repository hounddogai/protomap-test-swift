@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimMetricTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newTieredClaimMetric("code-631", title: "title-467")
        #expect(item.status == RevenueCycle.TieredClaimMetricStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newTieredClaimMetric("code-631", title: "title-467")
        try item.moveTo(RevenueCycle.TieredClaimMetricStatus.inReview)
        #expect(item.status == RevenueCycle.TieredClaimMetricStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newTieredClaimMetric("code-631", title: "title-467")
        item.status = RevenueCycle.TieredClaimMetricStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredClaimMetricStatus.`open`) }
    }
}
