@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalLanguageTierTests {
    @Test func startsInOpen() throws {
        let item = Consent.newRegionalLanguageTier("code-254", name: "name-943")
        #expect(item.status == Consent.RegionalLanguageTierStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newRegionalLanguageTier("code-254", name: "name-943")
        try item.moveTo(Consent.RegionalLanguageTierStatus.reopened)
        #expect(item.status == Consent.RegionalLanguageTierStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newRegionalLanguageTier("code-254", name: "name-943")
        item.status = Consent.RegionalLanguageTierStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalLanguageTierStatus.`open`) }
    }
}
