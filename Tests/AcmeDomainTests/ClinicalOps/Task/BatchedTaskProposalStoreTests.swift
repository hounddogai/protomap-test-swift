@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryBatchedTaskProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.BatchedTaskProposalStore = ClinicalOps.newMemoryBatchedTaskProposalStore()
        let item = ClinicalOps.newBatchedTaskProposal("code-436", label: "label-480")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
