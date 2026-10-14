@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryClaimProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ClaimProposalStore = RevenueCycle.newMemoryClaimProposalStore()
        let item = RevenueCycle.newClaimProposal("code-735", name: "name-861")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
