@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultProxyProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultProxyProposalStore = Consent.newMemoryDefaultProxyProposalStore()
        let item = Consent.newDefaultProxyProposal("code-503", label: "label-460")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
