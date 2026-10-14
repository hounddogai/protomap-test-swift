@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalWitnessDigestTests {
    @Test func startsInProposed() throws {
        let item = Consent.newSeasonalWitnessDigest("code-115", name: "name-380")
        #expect(item.status == Consent.SeasonalWitnessDigestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newSeasonalWitnessDigest("code-115", name: "name-380")
        try item.moveTo(Consent.SeasonalWitnessDigestStatus.rejected)
        #expect(item.status == Consent.SeasonalWitnessDigestStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newSeasonalWitnessDigest("code-115", name: "name-380")
        item.status = Consent.SeasonalWitnessDigestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalWitnessDigestStatus.proposed) }
    }
}
