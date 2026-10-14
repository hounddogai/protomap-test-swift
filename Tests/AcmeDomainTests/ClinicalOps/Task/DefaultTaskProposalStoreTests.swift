@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultTaskProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultTaskProposalStore = ClinicalOps.newMemoryDefaultTaskProposalStore()
        let item = ClinicalOps.newDefaultTaskProposal("code-658", label: "label-357")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
