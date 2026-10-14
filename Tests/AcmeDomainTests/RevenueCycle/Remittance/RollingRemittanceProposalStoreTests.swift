@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRollingRemittanceProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RollingRemittanceProposalStore = RevenueCycle.newMemoryRollingRemittanceProposalStore()
        let item = RevenueCycle.newRollingRemittanceProposal("code-362", title: "title-744")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
