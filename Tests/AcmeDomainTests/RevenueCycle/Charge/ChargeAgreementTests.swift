@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeAgreementTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newChargeAgreement("code-152", name: "name-791")
        #expect(item.status == RevenueCycle.ChargeAgreementStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = RevenueCycle.newChargeAgreement("code-152", name: "name-791")
        try item.moveTo(RevenueCycle.ChargeAgreementStatus.retired)
        #expect(item.status == RevenueCycle.ChargeAgreementStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newChargeAgreement("code-152", name: "name-791")
        item.status = RevenueCycle.ChargeAgreementStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeAgreementStatus.created) }
    }
}
