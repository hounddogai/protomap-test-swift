@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPendingTaskProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PendingTaskProposalStore = ClinicalOps.newMemoryPendingTaskProposalStore()
        let item = ClinicalOps.newPendingTaskProposal("code-776", label: "label-775")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
