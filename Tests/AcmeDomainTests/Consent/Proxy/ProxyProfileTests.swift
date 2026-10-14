@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyProfileTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newProxyProfile("code-28", title: "title-168")
        #expect(item.status == Consent.ProxyProfileStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newProxyProfile("code-28", title: "title-168")
        try item.moveTo(Consent.ProxyProfileStatus.completed)
        #expect(item.status == Consent.ProxyProfileStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newProxyProfile("code-28", title: "title-168")
        item.status = Consent.ProxyProfileStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyProfileStatus.planned) }
    }
}
