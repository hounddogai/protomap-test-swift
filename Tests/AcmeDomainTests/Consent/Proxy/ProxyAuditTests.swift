@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyAuditTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newProxyAudit("code-870", title: "title-510")
        #expect(item.status == Consent.ProxyAuditStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newProxyAudit("code-870", title: "title-510")
        try item.moveTo(Consent.ProxyAuditStatus.scheduled)
        #expect(item.status == Consent.ProxyAuditStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newProxyAudit("code-870", title: "title-510")
        item.status = Consent.ProxyAuditStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyAuditStatus.planned) }
    }
}
