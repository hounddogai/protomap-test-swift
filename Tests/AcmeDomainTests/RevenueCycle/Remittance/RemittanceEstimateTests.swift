@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceEstimateTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newRemittanceEstimate("code-29", name: "name-232")
        #expect(item.status == RevenueCycle.RemittanceEstimateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newRemittanceEstimate("code-29", name: "name-232")
        try item.moveTo(RevenueCycle.RemittanceEstimateStatus.inReview)
        #expect(item.status == RevenueCycle.RemittanceEstimateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newRemittanceEstimate("code-29", name: "name-232")
        item.status = RevenueCycle.RemittanceEstimateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceEstimateStatus.`open`) }
    }
}
