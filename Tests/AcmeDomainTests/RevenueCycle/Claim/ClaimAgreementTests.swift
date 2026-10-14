@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimAgreementTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newClaimAgreement("code-229", name: "name-710")
        #expect(item.status == RevenueCycle.ClaimAgreementStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newClaimAgreement("code-229", name: "name-710")
        try item.moveTo(RevenueCycle.ClaimAgreementStatus.resolved)
        #expect(item.status == RevenueCycle.ClaimAgreementStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newClaimAgreement("code-229", name: "name-710")
        item.status = RevenueCycle.ClaimAgreementStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimAgreementStatus.`open`) }
    }
}
