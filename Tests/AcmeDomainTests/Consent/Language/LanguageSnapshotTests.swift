@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageSnapshotTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newLanguageSnapshot("code-260", label: "label-903")
        #expect(item.status == Consent.LanguageSnapshotStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newLanguageSnapshot("code-260", label: "label-903")
        try item.moveTo(Consent.LanguageSnapshotStatus.scheduled)
        #expect(item.status == Consent.LanguageSnapshotStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newLanguageSnapshot("code-260", label: "label-903")
        item.status = Consent.LanguageSnapshotStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LanguageSnapshotStatus.planned) }
    }
}
