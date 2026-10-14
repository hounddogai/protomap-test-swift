@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalClaimAgreementTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newGlobalClaimAgreement("code-990", name: "name-102")
        #expect(item.status == RevenueCycle.GlobalClaimAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = RevenueCycle.newGlobalClaimAgreement("code-990", name: "name-102")
        try item.moveTo(RevenueCycle.GlobalClaimAgreementStatus.reopened)
        #expect(item.status == RevenueCycle.GlobalClaimAgreementStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newGlobalClaimAgreement("code-990", name: "name-102")
        item.status = RevenueCycle.GlobalClaimAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.GlobalClaimAgreementStatus.`open`) }
    }
}
