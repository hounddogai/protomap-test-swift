@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredDisclosureDigestTests {
    @Test func startsInProposed() throws {
        let item = Consent.newTieredDisclosureDigest("code-941", title: "title-969")
        #expect(item.status == Consent.TieredDisclosureDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newTieredDisclosureDigest("code-941", title: "title-969")
        try item.moveTo(Consent.TieredDisclosureDigestStatus.rejected)
        #expect(item.status == Consent.TieredDisclosureDigestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newTieredDisclosureDigest("code-941", title: "title-969")
        item.status = Consent.TieredDisclosureDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredDisclosureDigestStatus.proposed) }
    }
}
