@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationMetricTests {
    @Test func startsInProposed() throws {
        let item = Consent.newRevocationMetric("code-4", name: "name-587")
        #expect(item.status == Consent.RevocationMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newRevocationMetric("code-4", name: "name-587")
        try item.moveTo(Consent.RevocationMetricStatus.approved)
        #expect(item.status == Consent.RevocationMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newRevocationMetric("code-4", name: "name-587")
        item.status = Consent.RevocationMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationMetricStatus.proposed) }
    }
}
