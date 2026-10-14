@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWorklistReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WorklistReviewStore = Imaging.newMemoryWorklistReviewStore()
        let item = Imaging.newWorklistReview("code-384", label: "label-216")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
