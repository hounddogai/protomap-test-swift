@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskProposalStore = ClinicalOps.newMemoryTaskProposalStore()
        let item = ClinicalOps.newTaskProposal("code-428", title: "title-161")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
