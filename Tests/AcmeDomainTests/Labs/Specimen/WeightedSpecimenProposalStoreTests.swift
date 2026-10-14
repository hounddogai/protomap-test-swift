@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedSpecimenProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedSpecimenProposalStore = Labs.newMemoryWeightedSpecimenProposalStore()
        let item = Labs.newWeightedSpecimenProposal("code-53", title: "title-192")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
