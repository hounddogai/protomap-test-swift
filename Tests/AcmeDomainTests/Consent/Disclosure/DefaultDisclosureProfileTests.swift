@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultDisclosureProfileTests {
    @Test func startsInRequested() throws {
        let item = Consent.newDefaultDisclosureProfile("code-725", label: "label-393")
        #expect(item.status == Consent.DefaultDisclosureProfileStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newDefaultDisclosureProfile("code-725", label: "label-393")
        try item.moveTo(Consent.DefaultDisclosureProfileStatus.granted)
        #expect(item.status == Consent.DefaultDisclosureProfileStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newDefaultDisclosureProfile("code-725", label: "label-393")
        item.status = Consent.DefaultDisclosureProfileStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultDisclosureProfileStatus.requested) }
    }
}
