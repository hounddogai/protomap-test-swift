@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageEntryTests {
    @Test func startsInIdle() throws {
        let item = Consent.newLanguageEntry("code-841", label: "label-528")
        #expect(item.status == Consent.LanguageEntryStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newLanguageEntry("code-841", label: "label-528")
        try item.moveTo(Consent.LanguageEntryStatus.ready)
        #expect(item.status == Consent.LanguageEntryStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newLanguageEntry("code-841", label: "label-528")
        item.status = Consent.LanguageEntryStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageEntryStatus.idle) }
    }
}
