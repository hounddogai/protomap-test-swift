@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadProposalStore = Imaging.newMemoryReadProposalStore()
        let item = Imaging.newReadProposal("code-407", name: "name-145")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
