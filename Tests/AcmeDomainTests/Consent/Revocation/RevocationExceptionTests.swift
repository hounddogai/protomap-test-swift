@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationExceptionTests {
    @Test func startsInIdle() throws {
        let item = Consent.newRevocationException("code-874", name: "name-916")
        #expect(item.status == Consent.RevocationExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newRevocationException("code-874", name: "name-916")
        try item.moveTo(Consent.RevocationExceptionStatus.warming)
        #expect(item.status == Consent.RevocationExceptionStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newRevocationException("code-874", name: "name-916")
        item.status = Consent.RevocationExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationExceptionStatus.idle) }
    }
}
