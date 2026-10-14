@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeProposalStore = RevenueCycle.newMemoryChargeProposalStore()
        let item = RevenueCycle.newChargeProposal("code-170", name: "name-891")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
