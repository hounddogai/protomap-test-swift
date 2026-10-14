@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedProxyTargetTests {
    @Test func startsInCreated() throws {
        let item = Consent.newCappedProxyTarget("code-142", name: "name-196")
        #expect(item.status == Consent.CappedProxyTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newCappedProxyTarget("code-142", name: "name-196")
        try item.moveTo(Consent.CappedProxyTargetStatus.published)
        #expect(item.status == Consent.CappedProxyTargetStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newCappedProxyTarget("code-142", name: "name-196")
        item.status = Consent.CappedProxyTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedProxyTargetStatus.created) }
    }
}
