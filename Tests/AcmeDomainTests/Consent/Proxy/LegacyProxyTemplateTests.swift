@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyProxyTemplateTests {
    @Test func startsInRequested() throws {
        let item = Consent.newLegacyProxyTemplate("code-456", title: "title-844")
        #expect(item.status == Consent.LegacyProxyTemplateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newLegacyProxyTemplate("code-456", title: "title-844")
        try item.moveTo(Consent.LegacyProxyTemplateStatus.granted)
        #expect(item.status == Consent.LegacyProxyTemplateStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newLegacyProxyTemplate("code-456", title: "title-844")
        item.status = Consent.LegacyProxyTemplateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.LegacyProxyTemplateStatus.requested) }
    }
}
