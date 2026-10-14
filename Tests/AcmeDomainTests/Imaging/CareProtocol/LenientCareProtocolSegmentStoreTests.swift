@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientCareProtocolSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientCareProtocolSegmentStore = Imaging.newMemoryLenientCareProtocolSegmentStore()
        let item = Imaging.newLenientCareProtocolSegment("code-231", title: "title-100")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
