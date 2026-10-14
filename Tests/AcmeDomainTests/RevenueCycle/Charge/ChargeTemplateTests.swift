@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeTemplateTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newChargeTemplate("code-29", label: "label-287")
        #expect(item.status == RevenueCycle.ChargeTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newChargeTemplate("code-29", label: "label-287")
        try item.moveTo(RevenueCycle.ChargeTemplateStatus.inReview)
        #expect(item.status == RevenueCycle.ChargeTemplateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newChargeTemplate("code-29", label: "label-287")
        item.status = RevenueCycle.ChargeTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeTemplateStatus.`open`) }
    }
}
