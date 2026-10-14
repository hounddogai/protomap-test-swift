@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalitySegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalitySegmentStore = Imaging.newMemoryModalitySegmentStore()
        let item = Imaging.newModalitySegment("code-827", title: "title-235")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
