@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyProposalStore = Consent.newMemoryProxyProposalStore()
        let item = Consent.newProxyProposal("code-336", name: "name-159")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
