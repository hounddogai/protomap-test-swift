@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWeightedReadProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WeightedReadProposalStore = Imaging.newMemoryWeightedReadProposalStore()
        let item = Imaging.newWeightedReadProposal("code-118", label: "label-665")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
