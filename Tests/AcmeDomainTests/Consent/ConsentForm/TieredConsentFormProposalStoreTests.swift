@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryTieredConsentFormProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.TieredConsentFormProposalStore = Consent.newMemoryTieredConsentFormProposalStore()
        let item = Consent.newTieredConsentFormProposal("code-149", label: "label-272")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
