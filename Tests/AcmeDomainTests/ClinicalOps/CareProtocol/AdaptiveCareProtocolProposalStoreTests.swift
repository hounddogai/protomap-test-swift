@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAdaptiveCareProtocolProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AdaptiveCareProtocolProposalStore = ClinicalOps.newMemoryAdaptiveCareProtocolProposalStore()
        let item = ClinicalOps.newAdaptiveCareProtocolProposal("code-781", label: "label-857")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
