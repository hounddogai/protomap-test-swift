@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMappingTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newProxyMapping("code-92", title: "title-752")
        #expect(item.status == Consent.ProxyMappingStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newProxyMapping("code-92", title: "title-752")
        try item.moveTo(Consent.ProxyMappingStatus.scheduled)
        #expect(item.status == Consent.ProxyMappingStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newProxyMapping("code-92", title: "title-752")
        item.status = Consent.ProxyMappingStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyMappingStatus.planned) }
    }
}
