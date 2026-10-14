@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyMilestoneTests {
    @Test func startsInCreated() throws {
        let item = Consent.newProxyMilestone("code-524", name: "name-395")
        #expect(item.status == Consent.ProxyMilestoneStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newProxyMilestone("code-524", name: "name-395")
        try item.moveTo(Consent.ProxyMilestoneStatus.published)
        #expect(item.status == Consent.ProxyMilestoneStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newProxyMilestone("code-524", name: "name-395")
        item.status = Consent.ProxyMilestoneStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyMilestoneStatus.created) }
    }
}
