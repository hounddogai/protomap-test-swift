@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryManualConsentFormProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ManualConsentFormProposalStore = Consent.newMemoryManualConsentFormProposalStore()
        let item = Consent.newManualConsentFormProposal("code-30", name: "name-732")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
