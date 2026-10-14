@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLegacyModalityReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LegacyModalityReviewStore = Imaging.newMemoryLegacyModalityReviewStore()
        let item = Imaging.newLegacyModalityReview("code-133", label: "label-58")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
