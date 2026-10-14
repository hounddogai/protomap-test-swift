@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalRevocationPolicyTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newSeasonalRevocationPolicy("code-761", name: "name-126")
        #expect(item.status == Consent.SeasonalRevocationPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newSeasonalRevocationPolicy("code-761", name: "name-126")
        try item.moveTo(Consent.SeasonalRevocationPolicyStatus.scheduled)
        #expect(item.status == Consent.SeasonalRevocationPolicyStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newSeasonalRevocationPolicy("code-761", name: "name-126")
        item.status = Consent.SeasonalRevocationPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalRevocationPolicyStatus.planned) }
    }
}
