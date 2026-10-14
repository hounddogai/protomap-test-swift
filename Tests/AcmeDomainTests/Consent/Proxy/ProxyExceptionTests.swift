@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyExceptionTests {
    @Test func startsInIdle() throws {
        let item = Consent.newProxyException("code-305", label: "label-368")
        #expect(item.status == Consent.ProxyExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newProxyException("code-305", label: "label-368")
        try item.moveTo(Consent.ProxyExceptionStatus.warming)
        #expect(item.status == Consent.ProxyExceptionStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newProxyException("code-305", label: "label-368")
        item.status = Consent.ProxyExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyExceptionStatus.idle) }
    }
}
