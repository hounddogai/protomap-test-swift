@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeTargetTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newChargeTarget("code-909", title: "title-541")
        #expect(item.status == RevenueCycle.ChargeTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newChargeTarget("code-909", title: "title-541")
        try item.moveTo(RevenueCycle.ChargeTargetStatus.inReview)
        #expect(item.status == RevenueCycle.ChargeTargetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newChargeTarget("code-909", title: "title-541")
        item.status = RevenueCycle.ChargeTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeTargetStatus.`open`) }
    }
}
