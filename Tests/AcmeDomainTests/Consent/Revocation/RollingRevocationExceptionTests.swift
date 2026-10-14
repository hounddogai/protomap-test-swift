@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationExceptionTests {
    @Test func startsInRequested() throws {
        let item = Consent.newRollingRevocationException("code-368", label: "label-734")
        #expect(item.status == Consent.RollingRevocationExceptionStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newRollingRevocationException("code-368", label: "label-734")
        try item.moveTo(Consent.RollingRevocationExceptionStatus.granted)
        #expect(item.status == Consent.RollingRevocationExceptionStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newRollingRevocationException("code-368", label: "label-734")
        item.status = Consent.RollingRevocationExceptionStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingRevocationExceptionStatus.requested) }
    }
}
