@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackReferenceRangeProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackReferenceRangeProposalStore = Labs.newMemoryFallbackReferenceRangeProposalStore()
        let item = Labs.newFallbackReferenceRangeProposal("code-234", name: "name-396")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
