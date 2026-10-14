@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentSeasonalLanguageRequestTests {
    @Test func startsInNew() throws {
        let item = Consent.newSeasonalLanguageRequest("code-28", name: "name-248")
        #expect(item.status == Consent.SeasonalLanguageRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newSeasonalLanguageRequest("code-28", name: "name-248")
        try item.moveTo(Consent.SeasonalLanguageRequestStatus.running)
        #expect(item.status == Consent.SeasonalLanguageRequestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newSeasonalLanguageRequest("code-28", name: "name-248")
        item.status = Consent.SeasonalLanguageRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.SeasonalLanguageRequestStatus.new) }
    }
}
