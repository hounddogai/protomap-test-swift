@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalProxyBaselineTests {
    @Test func startsInProposed() throws {
        let item = Consent.newRegionalProxyBaseline("code-640", name: "name-506")
        #expect(item.status == Consent.RegionalProxyBaselineStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newRegionalProxyBaseline("code-640", name: "name-506")
        try item.moveTo(Consent.RegionalProxyBaselineStatus.approved)
        #expect(item.status == Consent.RegionalProxyBaselineStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newRegionalProxyBaseline("code-640", name: "name-506")
        item.status = Consent.RegionalProxyBaselineStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalProxyBaselineStatus.proposed) }
    }
}
