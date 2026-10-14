@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedProxyGroupTests {
    @Test func startsInOpen() throws {
        let item = Consent.newWeightedProxyGroup("code-74", title: "title-444")
        #expect(item.status == Consent.WeightedProxyGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Consent.newWeightedProxyGroup("code-74", title: "title-444")
        try item.moveTo(Consent.WeightedProxyGroupStatus.archived)
        #expect(item.status == Consent.WeightedProxyGroupStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newWeightedProxyGroup("code-74", title: "title-444")
        item.status = Consent.WeightedProxyGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WeightedProxyGroupStatus.`open`) }
    }
}
