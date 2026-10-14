@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLegacyOrderSetProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LegacyOrderSetProposalStore = ClinicalOps.newMemoryLegacyOrderSetProposalStore()
        let item = ClinicalOps.newLegacyOrderSetProposal("code-16", label: "label-251")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
