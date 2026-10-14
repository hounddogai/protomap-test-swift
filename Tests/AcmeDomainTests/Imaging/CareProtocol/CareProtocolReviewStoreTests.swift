@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolReviewStore = Imaging.newMemoryCareProtocolReviewStore()
        let item = Imaging.newCareProtocolReview("code-976", label: "label-301")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
