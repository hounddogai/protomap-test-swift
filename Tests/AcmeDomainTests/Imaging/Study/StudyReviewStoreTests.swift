@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudyReviewStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudyReviewStore = Imaging.newMemoryStudyReviewStore()
        let item = Imaging.newStudyReview("code-27", title: "title-445")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
