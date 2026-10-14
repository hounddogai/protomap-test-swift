@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureClaimTests {
    @Test func startsInProposed() throws {
        let item = Consent.newDisclosureClaim("code-394", name: "name-446")
        #expect(item.status == Consent.DisclosureClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newDisclosureClaim("code-394", name: "name-446")
        try item.moveTo(Consent.DisclosureClaimStatus.rejected)
        #expect(item.status == Consent.DisclosureClaimStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newDisclosureClaim("code-394", name: "name-446")
        item.status = Consent.DisclosureClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureClaimStatus.proposed) }
    }
}
