@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedProxyProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedProxyProposalStore = Consent.newMemoryCappedProxyProposalStore()
        let item = Consent.newCappedProxyProposal("code-883", name: "name-331")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
