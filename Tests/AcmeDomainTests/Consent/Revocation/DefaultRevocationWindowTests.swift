@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultRevocationWindowTests {
    @Test func startsInRequested() throws {
        let item = Consent.newDefaultRevocationWindow("code-327", label: "label-189")
        #expect(item.status == Consent.DefaultRevocationWindowStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newDefaultRevocationWindow("code-327", label: "label-189")
        try item.moveTo(Consent.DefaultRevocationWindowStatus.granted)
        #expect(item.status == Consent.DefaultRevocationWindowStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newDefaultRevocationWindow("code-327", label: "label-189")
        item.status = Consent.DefaultRevocationWindowStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultRevocationWindowStatus.requested) }
    }
}
