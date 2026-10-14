@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPendingReadProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PendingReadProposalStore = Imaging.newMemoryPendingReadProposalStore()
        let item = Imaging.newPendingReadProposal("code-392", label: "label-981")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
