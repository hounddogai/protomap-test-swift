@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalProxyAuditTests {
    @Test func startsInOpen() throws {
        let item = Consent.newGlobalProxyAudit("code-45", title: "title-226")
        #expect(item.status == Consent.GlobalProxyAuditStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newGlobalProxyAudit("code-45", title: "title-226")
        try item.moveTo(Consent.GlobalProxyAuditStatus.resolved)
        #expect(item.status == Consent.GlobalProxyAuditStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newGlobalProxyAudit("code-45", title: "title-226")
        item.status = Consent.GlobalProxyAuditStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalProxyAuditStatus.`open`) }
    }
}
