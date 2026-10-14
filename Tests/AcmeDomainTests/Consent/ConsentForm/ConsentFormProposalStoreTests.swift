@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormProposalStore = Consent.newMemoryConsentFormProposalStore()
        let item = Consent.newConsentFormProposal("code-413", label: "label-661")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
