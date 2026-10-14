@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityReviewStore = Imaging.newMemoryModalityReviewStore()
        let item = Imaging.newModalityReview("code-761", title: "title-759")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
