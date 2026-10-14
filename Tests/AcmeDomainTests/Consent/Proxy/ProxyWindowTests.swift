@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyWindowTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newProxyWindow("code-264", label: "label-866")
        #expect(item.status == Consent.ProxyWindowStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Consent.newProxyWindow("code-264", label: "label-866")
        try item.moveTo(Consent.ProxyWindowStatus.cancelled)
        #expect(item.status == Consent.ProxyWindowStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newProxyWindow("code-264", label: "label-866")
        item.status = Consent.ProxyWindowStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyWindowStatus.planned) }
    }
}
