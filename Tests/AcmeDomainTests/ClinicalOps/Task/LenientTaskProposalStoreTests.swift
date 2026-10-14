@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLenientTaskProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LenientTaskProposalStore = ClinicalOps.newMemoryLenientTaskProposalStore()
        let item = ClinicalOps.newLenientTaskProposal("code-873", label: "label-173")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
