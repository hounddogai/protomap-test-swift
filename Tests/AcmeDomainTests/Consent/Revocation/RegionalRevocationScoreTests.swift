@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationScoreTests {
    @Test func startsInOpen() throws {
        let item = Consent.newRegionalRevocationScore("code-553", label: "label-414")
        #expect(item.status == Consent.RegionalRevocationScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Consent.newRegionalRevocationScore("code-553", label: "label-414")
        try item.moveTo(Consent.RegionalRevocationScoreStatus.reopened)
        #expect(item.status == Consent.RegionalRevocationScoreStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newRegionalRevocationScore("code-553", label: "label-414")
        item.status = Consent.RegionalRevocationScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalRevocationScoreStatus.`open`) }
    }
}
