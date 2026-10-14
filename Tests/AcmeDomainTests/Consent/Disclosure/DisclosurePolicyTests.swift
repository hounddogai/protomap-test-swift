@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosurePolicyTests {
    @Test func startsInProposed() throws {
        let item = Consent.newDisclosurePolicy("code-417", name: "name-496")
        #expect(item.status == Consent.DisclosurePolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newDisclosurePolicy("code-417", name: "name-496")
        try item.moveTo(Consent.DisclosurePolicyStatus.rejected)
        #expect(item.status == Consent.DisclosurePolicyStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newDisclosurePolicy("code-417", name: "name-496")
        item.status = Consent.DisclosurePolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosurePolicyStatus.proposed) }
    }
}
