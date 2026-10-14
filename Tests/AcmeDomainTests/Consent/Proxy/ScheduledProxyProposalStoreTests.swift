@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledProxyProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledProxyProposalStore = Consent.newMemoryScheduledProxyProposalStore()
        let item = Consent.newScheduledProxyProposal("code-142", label: "label-114")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
