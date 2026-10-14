@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryManualRemittanceProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ManualRemittanceProposalStore = RevenueCycle.newMemoryManualRemittanceProposalStore()
        let item = RevenueCycle.newManualRemittanceProposal("code-751", title: "title-364")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
