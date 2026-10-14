@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredCareProtocolSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredCareProtocolSegmentStore = Imaging.newMemoryTieredCareProtocolSegmentStore()
        let item = Imaging.newTieredCareProtocolSegment("code-816", label: "label-10")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
