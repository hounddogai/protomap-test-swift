@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffProposalStore = ClinicalOps.newMemoryHandoffProposalStore()
        let item = ClinicalOps.newHandoffProposal("code-514", name: "name-566")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
