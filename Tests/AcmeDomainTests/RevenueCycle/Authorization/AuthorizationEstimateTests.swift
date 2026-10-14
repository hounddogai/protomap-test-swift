@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationEstimateTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newAuthorizationEstimate("code-714", title: "title-774")
        #expect(item.status == RevenueCycle.AuthorizationEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newAuthorizationEstimate("code-714", title: "title-774")
        try item.moveTo(RevenueCycle.AuthorizationEstimateStatus.inReview)
        #expect(item.status == RevenueCycle.AuthorizationEstimateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newAuthorizationEstimate("code-714", title: "title-774")
        item.status = RevenueCycle.AuthorizationEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationEstimateStatus.`open`) }
    }
}
