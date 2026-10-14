@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageWindowTests {
    @Test func startsInProposed() throws {
        let item = Consent.newLanguageWindow("code-951", label: "label-48")
        #expect(item.status == Consent.LanguageWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Consent.newLanguageWindow("code-951", label: "label-48")
        try item.moveTo(Consent.LanguageWindowStatus.withdrawn)
        #expect(item.status == Consent.LanguageWindowStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newLanguageWindow("code-951", label: "label-48")
        item.status = Consent.LanguageWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageWindowStatus.proposed) }
    }
}
