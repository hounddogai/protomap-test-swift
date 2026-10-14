@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPrimaryStudyReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PrimaryStudyReviewStore = Imaging.newMemoryPrimaryStudyReviewStore()
        let item = Imaging.newPrimaryStudyReview("code-256", label: "label-867")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
