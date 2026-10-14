@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessProfileTests {
    @Test func startsInDraft() throws {
        let item = Consent.newWitnessProfile("code-240", label: "label-744")
        #expect(item.status == Consent.WitnessProfileStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Consent.newWitnessProfile("code-240", label: "label-744")
        try item.moveTo(Consent.WitnessProfileStatus.active)
        #expect(item.status == Consent.WitnessProfileStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newWitnessProfile("code-240", label: "label-744")
        item.status = Consent.WitnessProfileStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessProfileStatus.draft) }
    }
}
