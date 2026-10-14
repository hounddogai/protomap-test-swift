@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackHandoffProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackHandoffProposalStore = ClinicalOps.newMemoryFallbackHandoffProposalStore()
        let item = ClinicalOps.newFallbackHandoffProposal("code-773", name: "name-302")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
