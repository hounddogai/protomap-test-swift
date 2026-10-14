@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureGroupTests {
    @Test func startsInRequested() throws {
        let item = Consent.newDisclosureGroup("code-933", label: "label-460")
        #expect(item.status == Consent.DisclosureGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newDisclosureGroup("code-933", label: "label-460")
        try item.moveTo(Consent.DisclosureGroupStatus.granted)
        #expect(item.status == Consent.DisclosureGroupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newDisclosureGroup("code-933", label: "label-460")
        item.status = Consent.DisclosureGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureGroupStatus.requested) }
    }
}
