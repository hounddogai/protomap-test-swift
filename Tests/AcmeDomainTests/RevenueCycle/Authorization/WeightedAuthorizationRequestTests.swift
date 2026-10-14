@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedAuthorizationRequestTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newWeightedAuthorizationRequest("code-24", title: "title-124")
        #expect(item.status == RevenueCycle.WeightedAuthorizationRequestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newWeightedAuthorizationRequest("code-24", title: "title-124")
        try item.moveTo(RevenueCycle.WeightedAuthorizationRequestStatus.reopened)
        #expect(item.status == RevenueCycle.WeightedAuthorizationRequestStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newWeightedAuthorizationRequest("code-24", title: "title-124")
        item.status = RevenueCycle.WeightedAuthorizationRequestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedAuthorizationRequestStatus.`open`) }
    }
}
