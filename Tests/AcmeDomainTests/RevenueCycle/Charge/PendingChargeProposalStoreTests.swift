@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingChargeProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingChargeProposalStore = RevenueCycle.newMemoryPendingChargeProposalStore()
        let item = RevenueCycle.newPendingChargeProposal("code-758", title: "title-379")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
