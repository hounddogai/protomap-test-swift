@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyTemplateTests {
    @Test func startsInRequested() throws {
        let item = Consent.newProxyTemplate("code-450", title: "title-328")
        #expect(item.status == Consent.ProxyTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newProxyTemplate("code-450", title: "title-328")
        try item.moveTo(Consent.ProxyTemplateStatus.granted)
        #expect(item.status == Consent.ProxyTemplateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newProxyTemplate("code-450", title: "title-328")
        item.status = Consent.ProxyTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyTemplateStatus.requested) }
    }
}
