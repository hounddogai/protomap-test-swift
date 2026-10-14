@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryManualCareProtocolReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ManualCareProtocolReviewStore = Imaging.newMemoryManualCareProtocolReviewStore()
        let item = Imaging.newManualCareProtocolReview("code-383", title: "title-942")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
