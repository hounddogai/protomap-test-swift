@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyRecordTests {
    @Test func startsInProposed() throws {
        let item = Consent.newProxyRecord("code-440", name: "name-274")
        #expect(item.status == Consent.ProxyRecordStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newProxyRecord("code-440", name: "name-274")
        try item.moveTo(Consent.ProxyRecordStatus.approved)
        #expect(item.status == Consent.ProxyRecordStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newProxyRecord("code-440", name: "name-274")
        item.status = Consent.ProxyRecordStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyRecordStatus.proposed) }
    }
}
