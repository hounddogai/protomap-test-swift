@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessQuotaTests {
    @Test func startsInProposed() throws {
        let item = Consent.newWitnessQuota("code-479", name: "name-396")
        #expect(item.status == Consent.WitnessQuotaStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newWitnessQuota("code-479", name: "name-396")
        try item.moveTo(Consent.WitnessQuotaStatus.approved)
        #expect(item.status == Consent.WitnessQuotaStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newWitnessQuota("code-479", name: "name-396")
        item.status = Consent.WitnessQuotaStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessQuotaStatus.proposed) }
    }
}
