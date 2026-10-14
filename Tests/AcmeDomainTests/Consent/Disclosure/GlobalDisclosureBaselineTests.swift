@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureBaselineTests {
    @Test func startsInRequested() throws {
        let item = Consent.newGlobalDisclosureBaseline("code-615", name: "name-426")
        #expect(item.status == Consent.GlobalDisclosureBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newGlobalDisclosureBaseline("code-615", name: "name-426")
        try item.moveTo(Consent.GlobalDisclosureBaselineStatus.granted)
        #expect(item.status == Consent.GlobalDisclosureBaselineStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newGlobalDisclosureBaseline("code-615", name: "name-426")
        item.status = Consent.GlobalDisclosureBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalDisclosureBaselineStatus.requested) }
    }
}
