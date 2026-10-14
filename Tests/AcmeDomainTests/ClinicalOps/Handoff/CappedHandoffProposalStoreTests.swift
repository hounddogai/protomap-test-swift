@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCappedHandoffProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CappedHandoffProposalStore = ClinicalOps.newMemoryCappedHandoffProposalStore()
        let item = ClinicalOps.newCappedHandoffProposal("code-219", title: "title-842")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
