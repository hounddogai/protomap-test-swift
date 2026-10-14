@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyQuotaTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newRegionalProxyQuota("code-364", name: "name-910")
        #expect(item.status == Consent.RegionalProxyQuotaStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newRegionalProxyQuota("code-364", name: "name-910")
        try item.moveTo(Consent.RegionalProxyQuotaStatus.completed)
        #expect(item.status == Consent.RegionalProxyQuotaStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newRegionalProxyQuota("code-364", name: "name-910")
        item.status = Consent.RegionalProxyQuotaStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalProxyQuotaStatus.planned) }
    }
}
