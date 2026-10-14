@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = Consent.newProxyAdjustment("code-949", label: "label-891")
        #expect(item.status == Consent.ProxyAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newProxyAdjustment("code-949", label: "label-891")
        try item.moveTo(Consent.ProxyAdjustmentStatus.resolved)
        #expect(item.status == Consent.ProxyAdjustmentStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newProxyAdjustment("code-949", label: "label-891")
        item.status = Consent.ProxyAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyAdjustmentStatus.`open`) }
    }
}
