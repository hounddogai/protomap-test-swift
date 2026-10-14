@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalDisclosureDigestTests {
    @Test func startsInProposed() throws {
        let item = Consent.newSeasonalDisclosureDigest("code-874", title: "title-654")
        #expect(item.status == Consent.SeasonalDisclosureDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newSeasonalDisclosureDigest("code-874", title: "title-654")
        try item.moveTo(Consent.SeasonalDisclosureDigestStatus.approved)
        #expect(item.status == Consent.SeasonalDisclosureDigestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newSeasonalDisclosureDigest("code-874", title: "title-654")
        item.status = Consent.SeasonalDisclosureDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalDisclosureDigestStatus.proposed) }
    }
}
