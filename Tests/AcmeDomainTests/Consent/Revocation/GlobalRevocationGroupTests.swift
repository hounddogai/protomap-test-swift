@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalRevocationGroupTests {
    @Test func startsInRequested() throws {
        let item = Consent.newGlobalRevocationGroup("code-257", title: "title-548")
        #expect(item.status == Consent.GlobalRevocationGroupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newGlobalRevocationGroup("code-257", title: "title-548")
        try item.moveTo(Consent.GlobalRevocationGroupStatus.granted)
        #expect(item.status == Consent.GlobalRevocationGroupStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newGlobalRevocationGroup("code-257", title: "title-548")
        item.status = Consent.GlobalRevocationGroupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalRevocationGroupStatus.requested) }
    }
}
