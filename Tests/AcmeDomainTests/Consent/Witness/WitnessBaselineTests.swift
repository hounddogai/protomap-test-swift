@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessBaselineTests {
    @Test func startsInDraft() throws {
        let item = Consent.newWitnessBaseline("code-649", label: "label-886")
        #expect(item.status == Consent.WitnessBaselineStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newWitnessBaseline("code-649", label: "label-886")
        try item.moveTo(Consent.WitnessBaselineStatus.pending)
        #expect(item.status == Consent.WitnessBaselineStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newWitnessBaseline("code-649", label: "label-886")
        item.status = Consent.WitnessBaselineStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessBaselineStatus.draft) }
    }
}
