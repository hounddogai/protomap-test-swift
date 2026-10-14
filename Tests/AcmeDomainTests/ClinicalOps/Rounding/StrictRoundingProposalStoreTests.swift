@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryStrictRoundingProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.StrictRoundingProposalStore = ClinicalOps.newMemoryStrictRoundingProposalStore()
        let item = ClinicalOps.newStrictRoundingProposal("code-716", title: "title-536")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
