@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityProposalStore = Imaging.newMemoryModalityProposalStore()
        let item = Imaging.newModalityProposal("code-692", name: "name-347")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
