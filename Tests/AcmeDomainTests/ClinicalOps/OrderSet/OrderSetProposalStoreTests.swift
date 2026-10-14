@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetProposalStore = ClinicalOps.newMemoryOrderSetProposalStore()
        let item = ClinicalOps.newOrderSetProposal("code-247", name: "name-96")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
