@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientReadProposalStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientReadProposalStore = Imaging.newMemoryLenientReadProposalStore()
        let item = Imaging.newLenientReadProposal("code-677", title: "title-633")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
