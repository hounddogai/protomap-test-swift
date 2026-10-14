@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredLanguageProfileTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newTieredLanguageProfile("code-870", title: "title-753")
        #expect(item.status == Consent.TieredLanguageProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newTieredLanguageProfile("code-870", title: "title-753")
        try item.moveTo(Consent.TieredLanguageProfileStatus.inProgress)
        #expect(item.status == Consent.TieredLanguageProfileStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newTieredLanguageProfile("code-870", title: "title-753")
        item.status = Consent.TieredLanguageProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredLanguageProfileStatus.planned) }
    }
}
