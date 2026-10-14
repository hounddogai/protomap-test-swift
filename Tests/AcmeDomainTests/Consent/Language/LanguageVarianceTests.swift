@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageVarianceTests {
    @Test func startsInNew() throws {
        let item = Consent.newLanguageVariance("code-687", title: "title-793")
        #expect(item.status == Consent.LanguageVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newLanguageVariance("code-687", title: "title-793")
        try item.moveTo(Consent.LanguageVarianceStatus.queued)
        #expect(item.status == Consent.LanguageVarianceStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newLanguageVariance("code-687", title: "title-793")
        item.status = Consent.LanguageVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageVarianceStatus.new) }
    }
}
