@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingStatementProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingStatementProposalStore = RevenueCycle.newMemoryPendingStatementProposalStore()
        let item = RevenueCycle.newPendingStatementProposal("code-452", name: "name-63")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
