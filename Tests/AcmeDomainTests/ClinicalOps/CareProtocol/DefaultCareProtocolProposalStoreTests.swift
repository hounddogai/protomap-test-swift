@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultCareProtocolProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultCareProtocolProposalStore = ClinicalOps.newMemoryDefaultCareProtocolProposalStore()
        let item = ClinicalOps.newDefaultCareProtocolProposal("code-916", title: "title-95")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
