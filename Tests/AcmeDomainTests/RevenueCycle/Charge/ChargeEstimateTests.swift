@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeEstimateTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newChargeEstimate("code-146", name: "name-865")
        #expect(item.status == RevenueCycle.ChargeEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newChargeEstimate("code-146", name: "name-865")
        try item.moveTo(RevenueCycle.ChargeEstimateStatus.inReview)
        #expect(item.status == RevenueCycle.ChargeEstimateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newChargeEstimate("code-146", name: "name-865")
        item.status = RevenueCycle.ChargeEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeEstimateStatus.`open`) }
    }
}
